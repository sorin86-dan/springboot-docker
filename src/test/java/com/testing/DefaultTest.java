package com.testing;

import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.testng.annotations.Test;

import java.io.IOException;

import static org.testng.Assert.assertEquals;

public class DefaultTest {

    @Test
    public void checkExceptionEndpoint() throws IOException {
        Response response = RestAssured.get("http://localhost:8080/exception").andReturn();

        assertEquals(response.getStatusCode(), 409);
        assertEquals(response.getBody().asString(), "Custom Exception");
    }

    @Test
    public void checkMessageEndpoint() throws IOException {
        Response response = RestAssured.get("http://localhost:8080/message?service=TestServiceX").andReturn();

        assertEquals(response.getStatusCode(), 200);
        assertEquals(response.getBody().asString(), "Hello, TestServiceX!");
    }

    @Test
    public void checkInvalidEndpoint() throws IOException {
        Response response = RestAssured.get("http://localhost:8080/mssage?service=TestServiceX").andReturn();

        assertEquals(response.getStatusCode(), 404);
    }

    @Test
    public void checkMessageEndpointInvalidParameter() throws IOException {
        Response response = RestAssured.get("http://localhost:8080/message?serviceX=TestServiceX").andReturn();

        assertEquals(response.getStatusCode(), 400);
    }
}