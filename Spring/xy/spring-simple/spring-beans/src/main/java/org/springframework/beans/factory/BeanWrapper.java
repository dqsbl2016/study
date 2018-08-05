package org.springframework.beans.factory;

public interface BeanWrapper {

    Class<?> getWrappedClass();

    Object getWrappedInstance();
}
