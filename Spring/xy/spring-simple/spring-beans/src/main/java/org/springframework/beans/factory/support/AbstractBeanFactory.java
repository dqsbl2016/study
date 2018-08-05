package org.springframework.beans.factory.support;

import org.springframework.beans.annotion.AutoWired;
import org.springframework.beans.annotion.Controller;
import org.springframework.beans.annotion.Service;
import org.springframework.beans.factory.*;

import java.lang.annotation.Annotation;
import java.lang.reflect.Field;
import java.util.Map;

public abstract class AbstractBeanFactory implements ListableBeanFactory,HierarchicalBeanFactory,AutowireCapableBeanFactory {
    @Override
    public <T> T createBean(Class<T> beanClass) {
        return null;
    }

    @Override
    public void applyBeanPropertyValues(Object existingBean, String beanName) {

    }

    @Override
    public void destroyBean(Object existingBean) {

    }

    @Override
    public BeanFactory getParentBeanFactory() {
        return null;
    }

    @Override
    public <T> Map<String, T> getBeansOfType(Class<T> type) {
        return null;
    }

    @Override
    public Map<String, Object> getBeansWithAnnotation(Class<? extends Annotation> annotationType) {
        return null;
    }

    @Override
    public Object getBean(String name) {
        return doGetBean(name);
    }

    protected abstract BeanDefinition getBeanDefinition(String beanName) ;

    protected abstract void registerBeanWrapper(String beanName,BeanWrapper beanWrapper) ;

    public Object doGetBean(String name){

        BeanWrapper instanceWrapper = doCreateBean(name);

        populateBean(instanceWrapper);

        return instanceWrapper.getWrappedInstance();
    }


    public BeanWrapper doCreateBean(String name){
        BeanDefinition beanDefinition = getBeanDefinition(name);
        try {
            Object beanInstance = null;
            try {
                beanInstance = Class.forName(beanDefinition.getBeanClassName().toString()).newInstance();
            } catch (ClassNotFoundException e) {
                e.printStackTrace();
            }
            BeanWrapper beanWrapper = new BeanWrapperImpl(beanInstance);
            registerBeanWrapper(name,beanWrapper);
            return beanWrapper;
        } catch (InstantiationException e) {
            e.printStackTrace();
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        }
        return null;
    }
    public void populateBean(BeanWrapper beanWrapper){

        try {
            Class clazz = beanWrapper.getWrappedInstance().getClass();
            if(!clazz.isAnnotationPresent(Controller.class)&&!clazz.isAnnotationPresent(Service.class)){
                return;
            }
            //属性注入没有实现。。  测试写死了一个属性   注入其实就是判断@autoWrie的
            Field[] fields  = beanWrapper.getWrappedInstance().getClass().getDeclaredFields();
            for(Field f:fields){
                if(!f.isAnnotationPresent(AutoWired.class)){
                    continue;
                }
                AutoWired auto = f.getAnnotation(AutoWired.class);
                String autoname = auto.value().trim();
                if("".equals(autoname)){
                    autoname = f.getType().getName();
                }
                f.setAccessible(true);
                Object jo = getObject(autoname);
                f.set(beanWrapper.getWrappedInstance(),jo);

            }
//            Field f  = beanWrapper.getWrappedInstance().getClass().getDeclaredField("snum");
//            f.setAccessible(true);
//            f.set(beanWrapper.getWrappedInstance(),18);
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        }
    }
    protected abstract Object getObject(String beanClassName) ;
}
