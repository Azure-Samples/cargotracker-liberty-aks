package org.eclipse.pathfinder.api;

import dev.langchain4j.model.azure.AzureOpenAiChatModel;
import dev.langchain4j.service.AiServices;
import jakarta.enterprise.context.ApplicationScoped;

@ApplicationScoped
public class ShortestPathAiImpl implements ShortestPathAi {
    private static final AzureOpenAiChatModel MODEL;
    private static final ShortestPathAi SHORTEST_PATH_AI;

    static {
        MODEL = AzureOpenAiChatModel.builder()
                .apiKey(System.getenv("AZURE_OPENAI_KEY"))
                .endpoint(System.getenv("AZURE_OPENAI_ENDPOINT"))
                .deploymentName(System.getenv("AZURE_OPENAI_DEPLOYMENT_NAME"))
                .temperature(0.2)
                .logRequestsAndResponses(true)
                .build();

        SHORTEST_PATH_AI = AiServices.builder(ShortestPathAi.class)
                .chatLanguageModel(MODEL)
                .build();
    }

    public ShortestPathAiImpl() {
        // Empty constructor
    }

    @Override
    public String chat(String location, String voyage, String carrier_movement, String from, String to) {
        return SHORTEST_PATH_AI.chat(location, voyage, carrier_movement, from, to);
    }
}
