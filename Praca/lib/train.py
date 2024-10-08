from transformers import AutoModelForCausalLM, AutoTokenizer, Trainer, TrainingArguments
from datasets import Dataset
import torch, pandas as pd
import os

# # Tokenization function to process each text prompt and completion pair
# def tokenize_function(examples):
#     # Concatenate the prompt and the completion for training
#     text = [prompt + " " + completion for prompt, completion in zip(examples['prompt'], examples['completion'])]
#     return tokenizer(text, padding="max_length", truncation=True)

# Load your dataset (ensure you have a CSV file with 'prompt' and 'completion' columns)
# data_path = "../Data/SampleTrainData.csv"
# data = pd.read_csv(data_path)
# dataset = Dataset.from_pandas(data)

# if __name__ == "__main__":
#     # Path to the model directory (use the existing model directory)
#     # model_dir = "../Model"

#     # Load the tokenizer and the model
#     # tokenizer = AutoTokenizer.from_pretrained(model_dir)
#     # model = AutoModelForCausalLM.from_pretrained(model_dir, torch_dtype=torch.float16, low_cpu_mem_usage=True)

#     # List the current contents of data directory
#     current_directory = os.getcwd()
#     parent_directory = os.path.abspath(os.path.join(current_directory, os.pardir))
#     data_directory = os.path.join(parent_directory, "Data")
#     print("\nCurrent data available to be trained with:\n")
#     for item in os.listdir(data_directory):
#         print(item)
    

# # Tokenize the dataset
# tokenized_dataset = dataset.map(tokenize_function, batched=True)

# # Define training arguments for fine-tuning
# training_args = TrainingArguments(
#     output_dir=model_dir,              # Save the fine-tuned model to the *same directory*
#     overwrite_output_dir=True,         # Overwrite the existing directory
#     evaluation_strategy="epoch",       # Evaluate at the end of each epoch
#     learning_rate=2e-5,                # Learning rate for fine-tuning
#     per_device_train_batch_size=4,     # Training batch size
#     num_train_epochs=10,                # Number of training epochs
#     weight_decay=0.01,                 # Weight decay for regularization
#     save_steps=100,                    # Save checkpoint every 100 steps
#     logging_dir='./logs',              # Directory for logs
#     logging_steps=10,                  # Log every 10 steps
#     save_total_limit=2                 # Limit number of saved checkpoints
# )

# # Create a Trainer object
# trainer = Trainer(
#     model=model,
#     args=training_args,
#     train_dataset=tokenized_dataset,
#     tokenizer=tokenizer,
# )

# # Train the model
# trainer.train()

# # Save the fine-tuned model and tokenizer to the *same directory*
# trainer.save_model(model_dir)  # This will overwrite the model in the same directory
# tokenizer.save_pretrained(model_dir)

# print(f"Model updated and saved successfully in {model_dir}")