package com.testing;

import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import java.io.IOException;

import static org.testng.Assert.assertEquals;

public class DefaultTest {

    private String ec2Ip;

    @Parameters("ec2-ip")
    @BeforeClass
    public void setUp(String ec2Ip) {
        this.ec2Ip = ec2Ip;
    }

    @Test
    public void checkExceptionEndpoint() throws IOException {
        Response response = RestAssured.get("http://" + ec2Ip + ":8081/exception").andReturn();

        assertEquals(response.getStatusCode(), 409);
        assertEquals(response.getBody().asString(), "Custom Exception");
    }

    @Test
    public void checkMessageEndpoint() throws IOException {
        Response response = RestAssured.get("http://" + ec2Ip + ":8081/message?service=TestServiceX").andReturn();

        assertEquals(response.getStatusCode(), 200);
        assertEquals(response.getBody().asString(), "Hello, TestServiceX!");
    }

    @Test
    public void checkInvalidEndpoint() throws IOException {
        Response response = RestAssured.get("http://" + ec2Ip + ":8081/mssage?service=TestServiceX").andReturn();

        assertEquals(response.getStatusCode(), 404);
    }

    @Test
    public void checkMessageEndpointInvalidParameter() throws IOException {
        Response response = RestAssured.get("http://" + ec2Ip + ":8081/message?serviceX=TestServiceX").andReturn();

        assertEquals(response.getStatusCode(), 400);
    }
}