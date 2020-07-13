package com.testing.services;

import org.springframework.stereotype.Service;

@Service
public class ServiceTest {
    public String helloService(String service) {
        return "Hello, " + service + "!";
    }
}
