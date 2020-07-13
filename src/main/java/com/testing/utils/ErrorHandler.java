package com.testing.utils;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

@ControllerAdvice
public class ErrorHandler extends ResponseEntityExceptionHandler {
    @ExceptionHandler(value = IllegalStateException.class)
    public ResponseEntity<Object> handleError(Exception ex, WebRequest request) {
        return handleExceptionInternal(ex, "Custom Exception", new HttpHeaders(), HttpStatus.CONFLICT, request);
    }
}
