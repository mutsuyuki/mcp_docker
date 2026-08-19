import json
from pathlib import Path

from huggingface_hub import snapshot_download


MODEL_ID = "Qwen/Qwen3-Embedding-0.6B"
MODEL_REVISION = "97b0c614be4d77ee51c0cef4e5f07c00f9eb65b3"
MODEL_DIR = Path("/models/Qwen3-Embedding-0.6B")
MARKER = MODEL_DIR / ".model-complete"
REQUIRED_FILES = ("config.json", "model.safetensors", "modules.json", "tokenizer.json")


def main() -> None:
    MODEL_DIR.mkdir(parents=True, exist_ok=True)
    snapshot_download(
        repo_id=MODEL_ID,
        revision=MODEL_REVISION,
        local_dir=MODEL_DIR,
    )

    missing = [name for name in REQUIRED_FILES if not (MODEL_DIR / name).is_file()]
    if missing:
        raise RuntimeError(f"Downloaded model is incomplete; missing: {', '.join(missing)}")

    MARKER.write_text(
        json.dumps(
            {"model_id": MODEL_ID, "revision": MODEL_REVISION},
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    print(f"Model ready: {MODEL_DIR}")


if __name__ == "__main__":
    main()
