package org.springframework.context.support;

public class ClassPathXmlApplicationContext extends AbstractApplicationContext {

    public ClassPathXmlApplicationContext(String... configLocations) {
        super(configLocations);
        refresh();
    }
}
