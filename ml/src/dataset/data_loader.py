import numpy as np
from sklearn.model_selection import train_test_split
import pandas as pd

def load_dummy_data(num_samples=100, num_classes=26, features=63):
    X = np.random.rand(num_samples * num_classes, features).astype(np.float32)
    y = np.repeat(np.arange(num_classes), num_samples).astype(np.int32)
    
    return train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

def load_real_data(data_path):
    # TODO: Load actual landmark data from Fadhil's extraction
    pass
