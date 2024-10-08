# from transformers import AutoModelForCausalLM, AutoTokenizer
# import torch

# # Path to the model directory
# model_dir = "../Model"

# # Load the tokenizer
# tokenizer = AutoTokenizer.from_pretrained(model_dir)

# # Load the model using the safetensors format
# model = AutoModelForCausalLM.from_pretrained(model_dir, torch_dtype=torch.float16, low_cpu_mem_usage=True)

# # Test the setup with a specific prompt
# input_text = "Give me a funny dad joke:"

# # Tokenize the input text
# inputs = tokenizer(input_text, return_tensors="pt")

# # Generate the output using the model
# outputs = model.generate(**inputs, max_length=500, num_return_sequences=1, no_repeat_ngram_size=2)

# # Decode and print the generated text
# print("Generated Text: ", tokenizer.decode(outputs[0], skip_special_tokens=True))