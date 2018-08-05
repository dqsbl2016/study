package org.springframework.beans.factory.support;

import org.springframework.beans.factory.BeanDefinitionReader;

public abstract class AbstractBeanDefinitionReader implements BeanDefinitionReader {

    @Override
    public int loadbeanDefinitions(String... locations) {
        int counter = 0;
        for(String lication:locations){
            counter += loadbeanDefinition(lication);
        }
        return counter;
    }

    @Override
    public int loadbeanDefinition(String location) {
        return doLoadBeanDefinition(location);
    }

    protected abstract int doLoadBeanDefinition(String location);


}
