package com.ssp.menuservice;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.NOT_FOUND)
public class NoSuchUnitException extends RuntimeException {
    public NoSuchUnitException(String unitId) {
        super("No menu found for unit " + unitId);
    }
}
