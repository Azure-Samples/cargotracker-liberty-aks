package org.eclipse.pathfinder.api;

import dev.langchain4j.model.azure.AzureOpenAiChatModel;
import dev.langchain4j.service.AiServices;
import jakarta.enterprise.context.ApplicationScoped;


// Implementation of our AI service using LangChain4j
@ApplicationScoped
public class ShortestPathAiImpl implements ShortestPathAi {
    private final ShortestPathAi ai;

    public ShortestPathAiImpl() {
        AzureOpenAiChatModel model = AzureOpenAiChatModel.builder()
                .apiKey(System.getenv("AZURE_OPENAI_KEY"))
                .endpoint(System.getenv("AZURE_OPENAI_ENDPOINT"))
                .deploymentName(System.getenv("AZURE_OPENAI_DEPLOYMENT_NAME"))
                .temperature(0.2)
                .logRequestsAndResponses(true)
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