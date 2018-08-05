package org.springframework;

import org.springframework.beans.annotion.Service;

@Service
public class Car {

    public String get(){
        return "Hello World";
    }
}
