import pandas as pd
import requests
import os

def download_dataset():
    # Create data directory if it doesn't exist
    os.makedirs('data', exist_ok=True)
    
    # URL for the Crop Recommendation Dataset
    url = "https://raw.githubusercontent.com/Gladiator07/Crop-Recommendation-System/master/Data/crop_recommendation.csv"
    
    try:
        # Download the dataset
        print("Downloading dataset...")
        response = requests.get(url)
        response.raise_for_status()  # Raise an exception for bad status codes
        
        # Save the dataset
        with open('data/crop_recommendation.csv', 'wb') as f:
            f.write(response.content)
        print("Dataset downloaded successfully!")
        
        # Verify the dataset
        df = pd.read_csv('data/crop_recommendation.csv')
        print(f"\nDataset shape: {df.shape}")
        print("\nFirst few rows:")
        print(df.head())
        print("\nAvailable crops:", sorted(df['label'].unique()))
        
    except Exception as e:
        print(f"Error downloading dataset: {str(e)}")
        return False
    
    return True

if __name__ == "__main__":
    download_dataset()
