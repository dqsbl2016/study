package org.springframework.beans.factory.support;

public class GenericBeanDefinition extends AbstractBeanDefinition {

    private String parentName;

    public String getParentName() {
        return parentName;
    }

    public void setParentName(String parentName) {
        this.parentName = parentName;
    }
}
