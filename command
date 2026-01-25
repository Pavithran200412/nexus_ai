# 1. Start Ollama
ollama serve

# 2. In NEW window - Test it works
curl http://localhost:11434

# 3. Pull model
ollama pull gemma2:2b

# 4. Test model
ollama run gemma2:2b
# Type: hello
# Press Ctrl+D to exit

# 5. Run your app
cd C:\Users\Pavit\Documents\nexus_ai
flutter clean
flutter run