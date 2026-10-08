import matplotlib.pyplot as plt
import os

def plot_training_history(history, save_dir):
    os.makedirs(save_dir, exist_ok=True)
    
    acc = history.history['accuracy']
    val_acc = history.history['val_accuracy']
    loss = history.history['loss']
    val_loss = history.history['val_loss']
    epochs = range(1, len(acc) + 1)
    
    plt.figure(figsize=(8, 6))
    plt.plot(epochs, acc, 'b-', label='Training Accuracy')
    plt.plot(epochs, val_acc, 'r-', label='Validation Accuracy')
    plt.title('Training and Validation Accuracy')
    plt.xlabel('Epochs')
    plt.ylabel('Accuracy')
    plt.legend()
    plt.grid(True)
    
    acc_path = os.path.join(save_dir, 'accuracy_plot.png')
    plt.savefig(acc_path)
    plt.close()
    
    plt.figure(figsize=(8, 6))
    plt.plot(epochs, loss, 'b-', label='Training Loss')
    plt.plot(epochs, val_loss, 'r-', label='Validation Loss')
    plt.title('Training and Validation Loss')
    plt.xlabel('Epochs')
    plt.ylabel('Loss')
    plt.legend()
    plt.grid(True)
    
    loss_path = os.path.join(save_dir, 'loss_plot.png')
    plt.savefig(loss_path)
    plt.close()
