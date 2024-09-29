package org.eclipse.pathfinder.api;

import dev.langchain4j.model.azure.AzureOpenAiChatModel;
import dev.langchain4j.service.AiServices;
import jakarta.enterprise.context.ApplicationScoped;

@ApplicationScoped
public class ShortestPathAiImpl implements ShortestPathAi {
    private final ShortestPathAi shortestPathAi;

    public ShortestPathAiImpl() {
        AzureOpenAiChatModel model = AzureOpenAiChatModel.builder()
                .apiKey(System.getenv("AZURE_OPENAI_KEY"))
                .endpoint(System.getenv("AZURE_OPENAI_ENDPOINT"))
                .deploymentName(System.getenv("AZURE_OPENAI_DEPLOYMENT_NAME"))
                .temperature(0.2)
                .logRequestsAndResponses(true)
                .build();

        // Create AI service
        this.shortestPathAi = AiServices.builder(ShortestPathAi.class)
                .chatLanguageModel(model)
                .build();
    }


    @Override
    public String chat(String location,String voyage, String carrier_movement, String from,String to) {
        return shortestPathAi.chat(location, voyage, carrier_movement, from, to);
    }
}
