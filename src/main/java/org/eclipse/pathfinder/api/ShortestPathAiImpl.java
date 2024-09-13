package org.eclipse.pathfinder.api;

import dev.langchain4j.model.openai.OpenAiChatModel;
import dev.langchain4j.service.AiServices;
import dev.langchain4j.service.V;
import jakarta.enterprise.context.ApplicationScoped;


// Implementation of our AI service using LangChain4j
@ApplicationScoped
public class ShortestPathAiImpl implements ShortestPathAi {
    private final ShortestPathAi ai;

    public ShortestPathAiImpl() {
        // Initialize OpenAI model
        OpenAiChatModel model = OpenAiChatModel.builder()
                .apiKey(System.getenv("OPENAI_API_KEY"))
                .build();

        // Create AI service
        this.ai = AiServices.builder(ShortestPathAi.class)
                .chatLanguageModel(model)
                .build();
    }


    @Override
    public String chat(String location,String voyage, String carrier_movement, String from,String to) {
        return ai.chat(location, voyage, carrier_movement, from, to);
    }
}