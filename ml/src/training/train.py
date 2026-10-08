import os
import sys

current_dir = os.path.dirname(os.path.abspath(__file__))
src_dir = os.path.dirname(current_dir)
sys.path.append(src_dir)

from dataset.data_loader import load_dummy_data
from training.model import build_classifier_model
from training.utils import plot_training_history
from tensorflow.keras.callbacks import ModelCheckpoint, EarlyStopping

def main():
    print("Starting training pipeline...")
    
    X_train, X_val, y_train, y_val = load_dummy_data(num_samples=100, num_classes=26, features=63)
    
    model = build_classifier_model(input_shape=(63,), num_classes=26)
    
    models_dir = os.path.join(os.path.dirname(src_dir), 'models')
    os.makedirs(models_dir, exist_ok=True)
    best_model_path = os.path.join(models_dir, 'bisindo_mlp_best.h5')
    
    callbacks = [
        ModelCheckpoint(
            filepath=best_model_path,
            monitor='val_accuracy',
            save_best_only=True,
            mode='max',
            verbose=1
        ),
        EarlyStopping(
            monitor='val_loss',
            patience=10,
            restore_best_weights=True,
            verbose=1
        )
    ]
    
    history = model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=30,
        batch_size=32,
        callbacks=callbacks,
        verbose=1
    )
    
    plot_training_history(history, save_dir=models_dir)
    print(f"Training finished. Best model saved to: {best_model_path}")

if __name__ == "__main__":
    main()
