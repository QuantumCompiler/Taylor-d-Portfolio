from transformers import AutoTokenizer, AutoModelForCausalLM
import torch

def PracaPrompt(model, tokenizer, device):
    # Get input
    userInput = input("Enter your prompt for Praca: ")
    # Tokenize the input and move to GPU
    input_ids = tokenizer(userInput, return_tensors="pt").to(device)
    # Generate the output using sampling-based techniques
    outputs = model.generate(
        **input_ids,
        do_sample=True,           # Enable sampling to introduce randomness
        top_k=100,                # Consider the top 100 options for sampling
        top_p=0.95,               # Or consider cumulative probability up to 95%
        temperature=0.75,         # Control randomness; 1.0 is neutral, lower is more deterministic
        max_length=1000,          # Adjust the max length to ensure long enough outputs
        num_return_sequences=1    # Number of different sequences to generate
    )
    return tokenizer.decode(outputs[0], skip_special_tokens=True)

if __name__ == "__main__":
    # Load the model using the pre-trained weights
    tokenizer = AutoTokenizer.from_pretrained("../Model")
    model = AutoModelForCausalLM.from_pretrained("../Model")
    # Check if a GPU is available and move the model to GPU
    if torch.cuda.is_available():
        device = torch.device("cuda")
    elif torch.backends.mps.is_available():
        device = torch.device("mps")
    else:
        device = torch.device("cpu")
    model.to(device)
    # Generate the output
    ret = PracaPrompt(model, tokenizer, device)
    print(ret)