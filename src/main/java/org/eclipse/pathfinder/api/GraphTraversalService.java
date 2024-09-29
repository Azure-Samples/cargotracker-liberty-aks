package org.eclipse.pathfinder.api;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Random;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import org.eclipse.pathfinder.internal.GraphDao;

@Stateless
@Path("/graph-traversal")
public class GraphTraversalService {

    private static final long ONE_MIN_MS = 1000 * 60;
    private static final long ONE_DAY_MS = ONE_MIN_MS * 60 * 24;
    private static final String UNLOCODE_PATTERN_VIOLATION_MESSAGE =
        "UN location code value must be five characters long, "
        + "the first two must be alphabetic and "
        + "the last three must be alphanumeric (excluding 0 and 1).";
    private final Random random = new Random();
    @Inject private GraphDao dao;
    @Inject
    private ShortestPathService service;

    @GET
    @Path("/shortest-path")
    @Produces({"application/json", "application/xml; qs=.75"})
    public List<TransitPath> findShortestPath(
                                              @NotNull(message = "Missing origin UN location code.")
                                              @Pattern(
                                                       regexp = "[a-zA-Z]{2}[a-zA-Z2-9]{3}",
                                                       message = "Origin " + UNLOCODE_PATTERN_VIOLATION_MESSAGE)
                                              @QueryParam("origin")
                                              String originUnLocode,
                                              @NotNull(message = "Missing destination UN location code.")
                                              @Pattern(
                                                       regexp = "[a-zA-Z]{2}[a-zA-Z2-9]{3}",
                                                       message = "Destination " + UNLOCODE_PATTERN_VIOLATION_MESSAGE)
                                              @QueryParam("destination")
                                              String destinationUnLocode,
                                              // TODO [DDD] Apply regular expression validation.
                                              @Size(min = 8, max = 8, message = "Deadline value must be eight characters long.")
                                              @QueryParam("deadline")
                                              String deadline) throws JsonProcessingException {
        if (!System.getenv("AZURE_OPENAI_ENDPOINT").isEmpty()
                && !System.getenv("AZURE_OPENAI_KEY").isEmpty()) {
            String shortestPath = getShortestPathWithTimeout(originUnLocode, destinationUnLocode);
            if (isValidJsonUsingJackson(shortestPath) && !shortestPath.equals("[]")) {
                ObjectMapper objectMapper = new ObjectMapper();
                objectMapper.registerModule(new JavaTimeModule());
                List<TransitPath> transitPaths = objectMapper.readValue(shortestPath, new TypeReference<>() {
                });
                if (transitPaths != null) {
                    return transitPaths;
                }
            }
        }

        List<String> allVertices = dao.listLocations();
        allVertices.remove(originUnLocode);
        allVertices.remove(destinationUnLocode);

        int candidateCount = getRandomNumberOfCandidates();
        List<TransitPath> candidates = new ArrayList<>(candidateCount);

        for (int i = 0; i < candidateCount; i++) {
            allVertices = getRandomChunkOfLocations(allVertices);
            List<TransitEdge> transitEdges = new ArrayList<>(allVertices.size() - 1);
            String fromUnLocode = originUnLocode;
            LocalDateTime date = LocalDateTime.now();

            for (int j = 0; j <= allVertices.size(); ++j) {
                LocalDateTime fromDate = nextDate(date);
                LocalDateTime toDate = nextDate(fromDate);
                String toUnLocode = (j >= allVertices.size() ? destinationUnLocode : allVertices.get(j));
                transitEdges.add(
                                 new TransitEdge(
                                                 dao.getVoyageNumber(fromUnLocode, toUnLocode),
                                                 fromUnLocode,
                                                 toUnLocode,
                                                 fromDate,
                                                 toDate));
                fromUnLocode = toUnLocode;
                date = nextDate(toDate);
            }
            candidates.add(new TransitPath(transitEdges));
        }
        return candidates;
    }

    private LocalDateTime nextDate(LocalDateTime date) {
        return date.plus(ONE_DAY_MS + (random.nextInt(1000) - 500) * ONE_MIN_MS, ChronoUnit.MILLIS);
    }

    private int getRandomNumberOfCandidates() {
        return 3 + random.nextInt(3);
    }

    private List<String> getRandomChunkOfLocations(List<String> allLocations) {
        Collections.shuffle(allLocations);
        int total = allLocations.size();
        int chunk = total > 4 ? 1 + random.nextInt(5) : total;
        return allLocations.subList(0, chunk);
    }

    private boolean isValidJsonUsingJackson(String jsonString) {
        try {
            ObjectMapper objectMapper = new ObjectMapper();
            objectMapper.readTree(jsonString);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    private String getShortestPathWithTimeout(String originUnLocode, String destinationUnLocode) {
        CompletableFuture<String> future = CompletableFuture.supplyAsync(() ->
                service.getShortestPath(originUnLocode, destinationUnLocode)
        );

        try {
            return future.completeOnTimeout("[]", 5, TimeUnit.SECONDS)
                    .get();
        } catch (Exception e) {
            e.printStackTrace();
            return "[]";
        }
    }

}
