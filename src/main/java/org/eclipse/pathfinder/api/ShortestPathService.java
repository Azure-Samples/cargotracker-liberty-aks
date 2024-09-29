package org.eclipse.pathfinder.api;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
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
        this.carrier_movement = new String(getClass().getClassLoader().getResourceAsStream("carrier_movement.csv").readAllBytes());
    }


    @GET
    @Path("/getShortestPath")
    @Produces(MediaType.TEXT_PLAIN)
    public String getShortestPath(@QueryParam("from") String from, @QueryParam("to") String to) {
        return shortestPathAi.chat(location,voyage,carrier_movement,from,to);
    }

    @GET
    @Path("/getLocation")
    @Produces(MediaType.TEXT_PLAIN)
    public String getLocation() {
        return this.location;
    }


    @GET
    @Path("/getMovement")
    @Produces(MediaType.TEXT_PLAIN)
    public String getMovement() {
        return this.carrier_movement;
    }
}
