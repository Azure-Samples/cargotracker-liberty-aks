package org.eclipse.pathfinder.api;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

// REST endpoint
@Path("/hello")
@ApplicationScoped
public class HelloWorldResource {

    private final HelloWorldAi helloWorldAi;

    public HelloWorldResource(HelloWorldAi helloWorldAi) {
        this.helloWorldAi = helloWorldAi;
    }

    @POST
    @Produces(MediaType.TEXT_PLAIN)
    @Consumes(MediaType.TEXT_PLAIN)
    public String hello(String message) {
        return helloWorldAi.chat(message);
    }
}