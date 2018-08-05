package org.springframework.beans.factory.support;

import org.springframework.beans.factory.BeanWrapper;

public class BeanWrapperImpl implements BeanWrapper {

    private Object wrappedObject;

    private Object originalObject;

    public BeanWrapperImpl(Object wrappedObject) {
        this.originalObject = wrappedObject;
        this.wrappedObject = wrappedObject;
    }

    @Override
    public Class<?> getWrappedClass() {
        return getWrappedInstance().getClass();
    }

    public Class<?> getOriginalObject(){
        return this.originalObject.getClass();
    }

    @Override
    public Object getWrappedInstance() {
        return this.wrappedObject;
    }

}
