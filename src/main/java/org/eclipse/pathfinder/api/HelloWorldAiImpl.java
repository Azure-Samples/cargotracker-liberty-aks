package org.eclipse.pathfinder.api;

import dev.langchain4j.model.openai.OpenAiChatModel;
import dev.langchain4j.service.AiServices;
import jakarta.enterprise.context.ApplicationScoped;


// Implementation of our AI service using LangChain4j
@ApplicationScoped
public class HelloWorldAiImpl implements HelloWorldAi {
    private final HelloWorldAi ai;

    public HelloWorldAiImpl() {
        // Initialize OpenAI model
        OpenAiChatModel model = OpenAiChatModel.builder()
                .apiKey(System.getenv("OPENAI_API_KEY"))
                .build();

        // Create AI service
        this.ai = AiServices.builder(HelloWorldAi.class)
                .chatLanguageModel(model)
                .build();
    }

    @Override
    public String chat(String message) {
        return ai.chat(message);
    }
}