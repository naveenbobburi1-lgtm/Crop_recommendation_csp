from pathlib import Path

import joblib
import numpy as np
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

BASE_DIR = Path(__file__).resolve().parent
MODEL_PATH = BASE_DIR / "model" / "crop_model.joblib"
SCALER_PATH = BASE_DIR / "model" / "scaler.joblib"
FRONTEND_ASSETS_DIR = BASE_DIR.parent / "frontend" / "assets"
CROP_IMAGES_DIR = FRONTEND_ASSETS_DIR / "crops"

if FRONTEND_ASSETS_DIR.exists():
    app.mount("/assets", StaticFiles(directory=FRONTEND_ASSETS_DIR), name="assets")


class SoilParams(BaseModel):
    N: float = Field(ge=0)
    P: float = Field(ge=0)
    K: float = Field(ge=0)
    temperature: float = Field(ge=0)
    humidity: float = Field(ge=0, le=100)
    ph: float = Field(ge=0, le=14)
    rainfall: float = Field(ge=0)


CROP_INFO = {
    "rice": {
        "description": (
            "Rice is a staple food crop that grows well in warm, humid "
            "conditions with adequate water supply."
        ),
        "cultivation_steps": [
            "Prepare land by plowing and leveling",
            "Soak seeds for 24 hours before sowing",
            "Maintain water level of 2-5 cm",
            "Apply fertilizers at recommended intervals",
            "Harvest when 80% of grains are mature",
        ],
        "optimal_conditions": {
            "temperature": "20-35 C",
            "humidity": "60-80%",
            "ph": "6.0-7.0",
            "rainfall": "100-200 cm/year",
        },
    },
    "wheat": {
        "description": (
            "Wheat is a cereal grain that thrives in moderate temperatures "
            "and well-drained soil."
        ),
        "cultivation_steps": [
            "Deep plow and prepare seedbed",
            "Sow seeds at proper spacing",
            "Irrigate at critical growth stages",
            "Monitor for pests and diseases",
            "Harvest when grains are hard",
        ],
        "optimal_conditions": {
            "temperature": "15-25 C",
            "humidity": "50-60%",
            "ph": "6.0-7.0",
            "rainfall": "60-100 cm/year",
        },
    },
}


def get_crop_image_url(crop_name: str) -> str | None:
    image_name = f"{crop_name.lower()}.png"
    image_path = CROP_IMAGES_DIR / image_name
    if image_path.exists():
        return f"/assets/crops/{image_name}"
    return None


@app.post("/recommend")
async def recommend_crop(params: SoilParams):
    try:
        import sklearn  # noqa: F401
    except ModuleNotFoundError as exc:
        raise HTTPException(
            status_code=500,
            detail=(
                "Required package 'scikit-learn' is missing. "
                "Install with 'pip install -r requirements.txt'."
            ),
        ) from exc

    if not MODEL_PATH.exists() or not SCALER_PATH.exists():
        raise HTTPException(
            status_code=500,
            detail="Model files not found. Please train the model first.",
        )

    try:
        model = joblib.load(MODEL_PATH)
        scaler = joblib.load(SCALER_PATH)

        features = np.array(
            [[
                params.N,
                params.P,
                params.K,
                params.temperature,
                params.humidity,
                params.ph,
                params.rainfall,
            ]]
        )
        features_scaled = scaler.transform(features)
        crop = str(model.predict(features_scaled)[0])
        probs = model.predict_proba(features_scaled)[0]
        confidence = float(max(probs))
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"Error making prediction: {exc}",
        ) from exc

    crop_key = crop.lower()
    crop_data = CROP_INFO.get(
        crop_key,
        {
            "description": f"General information for {crop} cultivation.",
            "cultivation_steps": [
                "Prepare soil properly",
                "Plant at the appropriate time",
                "Maintain proper irrigation",
                "Monitor crop health",
                "Harvest at maturity",
            ],
            "optimal_conditions": {
                "temperature": "Varies by region",
                "humidity": "Moderate",
                "ph": "6.0-7.0",
                "rainfall": "Adequate for crop needs",
            },
        },
    )

    return {
        "crop": crop,
        "confidence": confidence,
        "description": crop_data["description"],
        "cultivation_steps": crop_data["cultivation_steps"],
        "optimal_conditions": crop_data["optimal_conditions"],
        "image_url": get_crop_image_url(crop_key),
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
