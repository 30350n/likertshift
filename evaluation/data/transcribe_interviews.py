import logging
import sys
import typing
from pathlib import Path

import whisper


def transcribe_interviews(directory: Path):
    model = whisper.load_model("large")

    for path in directory.glob("**/interview.flac"):
        transcription_path = path.with_suffix(".md")
        relative_path = str(transcription_path.relative_to(directory))

        if transcription_path.is_file():
            logging.info("skipping '%s' (already transcribed)", relative_path)
            continue

        logging.info("transcribing '%s'", relative_path)
        transcription = model.transcribe(str(path))  # pyright: ignore[reportUnknownVariableType]

        transcription_text = typing.cast(str, transcription["text"])
        transcription_text = transcription_text.strip() + "\n"
        transcription_text = transcription_text.replace(". ", ".\n").replace("? ", "?\n")
        transcription_path.write_text(transcription_text, encoding="utf-8")


if __name__ == "__main__":
    logging.basicConfig(
        stream=sys.stdout,
        format="%(asctime)s %(levelname)-8s %(message)s",
        level=logging.INFO,
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    transcribe_interviews(Path(__file__).parent)
