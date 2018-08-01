package org.springframework.beans.factory.support;

import org.springframework.beans.factory.BeanWrapper;

public class BeanWrapperImpl implements BeanWrapper {

    private Object wrappedObject;

    public BeanWrapperImpl(Object wrappedObject) {
        this.wrappedObject = wrappedObject;
    }

    @Override
    public Class<?> getWrappedClass() {
        return getWrappedInstance().getClass();
    }

    @Override
    public Object getWrappedInstance() {
        return this.wrappedObject;
    }

}
