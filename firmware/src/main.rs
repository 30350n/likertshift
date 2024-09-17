#![no_std]
#![no_main]

use defmt_rtt as _;
use embassy_nrf as _;
use panic_probe as _;

use core::mem;

use defmt::{info, *};
use embassy_executor::Spawner;
use embassy_nrf::gpio::{Input, Level, Output, OutputDrive, Pin, Pull};
use embassy_nrf::interrupt::Priority;
use nrf_softdevice::ble::advertisement_builder::{
    Flag, LegacyAdvertisementBuilder, LegacyAdvertisementPayload, ServiceList, ServiceUuid16,
};
use nrf_softdevice::ble::{gatt_server, peripheral};
use nrf_softdevice::{raw, Softdevice};

#[embassy_executor::task]
async fn softdevice_task(sd: &'static Softdevice) -> ! {
    sd.run().await
}

#[nrf_softdevice::gatt_service(uuid = "180f")]
struct BatteryService {
    #[characteristic(uuid = "2a19", read, notify)]
    battery_level: u8,
}

#[nrf_softdevice::gatt_service(uuid = "b2a286dc-4521-5305-9f2a-42b070088000")]
struct LikertshiftService {
    #[characteristic(
        uuid = "b2a286dc-4521-5305-9f2a-42b070088001",
        read,
        write,
        notify,
        indicate
    )]
    value: u8,
}

#[nrf_softdevice::gatt_server]
struct Server {
    battery_service: BatteryService,
    likertshift_service: LikertshiftService,
}

#[embassy_executor::main]
async fn main(spawner: Spawner) {
    let mut config = embassy_nrf::config::Config::default();
    config.gpiote_interrupt_priority = Priority::P2;
    config.time_interrupt_priority = Priority::P2;
    let p = embassy_nrf::init(config);

    let config = nrf_softdevice::Config {
        clock: Some(raw::nrf_clock_lf_cfg_t {
            source: raw::NRF_CLOCK_LF_SRC_RC as u8,
            rc_ctiv: 16,
            rc_temp_ctiv: 2,
            accuracy: raw::NRF_CLOCK_LF_ACCURACY_500_PPM as u8,
        }),
        conn_gap: Some(raw::ble_gap_conn_cfg_t {
            conn_count: 6,
            event_length: 24,
        }),
        conn_gatt: Some(raw::ble_gatt_conn_cfg_t { att_mtu: 256 }),
        gatts_attr_tab_size: Some(raw::ble_gatts_cfg_attr_tab_size_t {
            attr_tab_size: raw::BLE_GATTS_ATTR_TAB_SIZE_DEFAULT,
        }),
        gap_role_count: Some(raw::ble_gap_cfg_role_count_t {
            adv_set_count: 1,
            periph_role_count: 3,
            central_role_count: 3,
            central_sec_count: 0,
            _bitfield_1: raw::ble_gap_cfg_role_count_t::new_bitfield_1(0),
        }),
        gap_device_name: Some(raw::ble_gap_cfg_device_name_t {
            p_value: b"Likertshift" as *const u8 as _,
            current_len: 11,
            max_len: 11,
            write_perm: unsafe { mem::zeroed() },
            _bitfield_1: raw::ble_gap_cfg_device_name_t::new_bitfield_1(
                raw::BLE_GATTS_VLOC_STACK as u8,
            ),
        }),
        ..Default::default()
    };

    let sd = Softdevice::enable(&config);
    let server = unwrap!(Server::new(sd));
    unwrap!(spawner.spawn(softdevice_task(sd)));

    static ADV_DATA: LegacyAdvertisementPayload = LegacyAdvertisementBuilder::new()
        .flags(&[Flag::GeneralDiscovery, Flag::LE_Only])
        .services_16(ServiceList::Complete, &[ServiceUuid16::BATTERY])
        .full_name("Likertshift")
        .build();

    static SCAN_DATA: LegacyAdvertisementPayload = LegacyAdvertisementBuilder::new()
        .services_128(
            ServiceList::Complete,
            &[0xb2a286dc_4521_5305_9f2a_42b070088001_u128.to_le_bytes()],
        )
        .build();

    let _output = Output::new(p.P0_02.degrade(), Level::High, OutputDrive::Standard);
    let input5 = Input::new(p.P0_03.degrade(), Pull::Down);
    let input4 = Input::new(p.P0_28.degrade(), Pull::Down);
    let input3 = Input::new(p.P0_29.degrade(), Pull::Down);
    let input2 = Input::new(p.P0_04.degrade(), Pull::Down);
    let input1 = Input::new(p.P0_05.degrade(), Pull::Down);
    let inputs = [input1, input2, input3, input4, input5];

    let mut value: u8 = 0;

    loop {
        let config = peripheral::Config::default();
        let adv = peripheral::ConnectableAdvertisement::ScannableUndirected {
            adv_data: &ADV_DATA,
            scan_data: &SCAN_DATA,
        };
        let conn = unwrap!(peripheral::advertise_connectable(sd, adv, &config).await);

        info!("advertising done!");

        let e = gatt_server::run(&conn, &server, |e| match e {
            ServerEvent::BatteryService(e) => match e {
                BatteryServiceEvent::BatteryLevelCccdWrite { notifications } => {
                    info!("battery notifications: {}", notifications)
                }
            },
            ServerEvent::LikertshiftService(e) => match e {
                LikertshiftServiceEvent::ValueWrite(_) => {
                    for (i, input) in inputs.iter().enumerate() {
                        if input.is_high() {
                            value = i as u8 + 1;
                        }
                    }
                    info!("position {}", value);
                    if let Err(e) = server.likertshift_service.value_notify(&conn, &value) {
                        info!("send notification error: {:?}", e);
                    }
                }
                LikertshiftServiceEvent::ValueCccdWrite {
                    indications,
                    notifications,
                } => {
                    info!(
                        "likershift indications: {}, notifications: {}",
                        indications, notifications
                    )
                }
            },
        })
        .await;

        info!("gatt_server run exited with error: {:?}", e);
    }
}
