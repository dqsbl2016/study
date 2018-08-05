package org.springframework.beans.factory;

public interface BeanDefinitionReader {

    int loadbeanDefinitions(String... locations);

    int loadbeanDefinition(String location);

}
