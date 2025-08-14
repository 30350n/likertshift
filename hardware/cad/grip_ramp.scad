TRACK_RADIUS = 18;
POSITIONS = 5;
MOVEMENT_RANGE = 160; // degrees
ANGLE_BETWEEN = MOVEMENT_RANGE / (POSITIONS - 1);

ROTATOR_WIDTH = 8;
ROTATOR_ANGLE = asin(ROTATOR_WIDTH / 2 / TRACK_RADIUS) * 2;
EXTRA_ANGLE = 8;

CUTOUT_SIZE = 3;

TRACK_SIZE = 6.8;
TRACK_OUTER_RADIUS = TRACK_RADIUS + TRACK_SIZE / 2;
TRACK_INNER_RADIUS = TRACK_RADIUS - TRACK_SIZE / 2;
TRACK_OUTER_HEIGHT = 2.6;
TRACK_INNER_HEIGHT = 2.2;
TRACK_START = atan((CUTOUT_SIZE / 2) / TRACK_RADIUS);

// CURVED_RAMP
function cumsum(vec) = [
    for (a=0, b=vec[0]; a < len(vec); a = a + 1, b = b + (vec[a] == undef ? 0 : vec[a])) b
];
function tri_sin(x, iter=32) = cumsum(
    [for (n=[1:2:iter*2]) (-1) ^ ((n - 1) / 2) * sin(n * x) / n ^ 2]
)[iter - 1] * 8 / PI ^ 2;

module curved_ramp(h, r_inner, r_outer, angle, fac_inner=1, fac_outer=1) {
    fn = $fn == undef || $fn == 0 ? 16 : $fn;
    function curve(r, x) = tri_sin(x / angle * 90) * h;
    function points(r) = [
        for (x = [angle / (fn - 1):angle / (fn - 1):angle])
        [r * cos(x), r * sin(x), curve(r, x)]
    ];
    function fac_z(points, fac) = [
        for (i = [0:len(points) - 1])
        [points[i].x, points[i].y, points[i].z * fac]
    ];

    start = [
        [r_inner, 0, 0],
        [r_outer, 0, 0],
    ];
    inner_top = fac_z(points(r_inner), fac_inner);
    inner_bot = fac_z(inner_top, 0);
    outer_top = fac_z(points(r_outer), fac_outer);
    outer_bot = fac_z(outer_top, 0);
    points = concat(start, inner_top, outer_top, inner_bot, outer_bot);

    end_faces = [
        [1, 0, 2],
        [2, fn + 1, 1],
        [0, 1, fn * 3 - 1, fn * 2],
        [0, fn * 2, 2],
        [1, fn + 1, fn * 3 - 1],
        [fn * 2 - 1, fn, fn * 3 - 2, fn * 4 - 3],
    ];
    segment_faces = [
        each for (i = [0:fn - 3]) [
            [fn + i + 1, i + 2, i + 3], // top 1
            [i + 3, fn + i + 2, fn + i + 1], // top 2
            [i + 3, i + 2, fn * 2 + i, fn * 2 + i + 1], // side inner
            [fn + i + 1, fn + i + 2, fn * 3 + i, fn * 3 - 1 + i], // side outer
            [fn * 2 + i + 1, fn * 2 + i, fn * 3 + i - 1, fn * 3 + i], // bottom
        ]
    ];
    faces = concat(end_faces, segment_faces);

    polyhedron(points, faces);
}

module curved_ramp_v(h_inner, h_outer, r_inner, r_outer, angle) {
    fac_inner = h_inner / h_outer;
    r_mid = (r_inner + r_outer) / 2;
    union() {
        curved_ramp(h_outer, r_inner, r_mid, angle, fac_outer=fac_inner);
        curved_ramp(h_outer, r_mid, r_outer, angle, fac_inner=fac_inner);
    };
}

// CURVED_RAMP

difference() {
    rotate([180, -90, 0])
    for (position = [0:POSITIONS-1]) {
        echo(floor(POSITIONS / 2) + 0.5);
        rotate([0, 0, (position - POSITIONS / 2 + 0.5) * ANGLE_BETWEEN])
        for (m = [0:1]) {
            mirror([0, m, 0])
            rotate([0, 0, TRACK_START - 0.1])
            curved_ramp_v(
                TRACK_INNER_HEIGHT,
                TRACK_OUTER_HEIGHT,
                TRACK_INNER_RADIUS, 
                TRACK_OUTER_RADIUS,
                ANGLE_BETWEEN / 2 - TRACK_START + 0.2,
                $fn=16
            );
        };
    }
    for (m = [0:1]) {
        mirror([0, m, 0])
        rotate([90 + (ROTATOR_ANGLE + MOVEMENT_RANGE + EXTRA_ANGLE) / 2, 0, 0])
        translate([-TRACK_OUTER_HEIGHT, 0, 0])
        cube([TRACK_OUTER_HEIGHT * 2, TRACK_OUTER_RADIUS, 10]);
    }
}
