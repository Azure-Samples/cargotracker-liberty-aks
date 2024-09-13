package org.eclipse.pathfinder.api;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;


// REST endpoint
@Path("/path")
@ApplicationScoped
public class ShortestPathService {

    @Inject
    private ShortestPathAi shortestPathAi;
    private final String location;
    private final String voyage;
    private final String carrier_movement;

    public ShortestPathService() throws Exception{
        this.location = new String(getClass().getClassLoader().getResourceAsStream("location.csv").readAllBytes());
        this.voyage = new String(getClass().getClassLoader().getResourceAsStream("voyage.csv").readAllBytes());
        carrier_movement = new String(getClass().getClassLoader().getResourceAsStream("carrier_movement.csv").readAllBytes());
    }


    @GET
    @Path("/shortest-path")
    @Produces(MediaType.TEXT_PLAIN)
    public String hello(@QueryParam("from") String from,@QueryParam("to") String to) {
        return shortestPathAi.chat(location,voyage,carrier_movement,from,to);
    }
}