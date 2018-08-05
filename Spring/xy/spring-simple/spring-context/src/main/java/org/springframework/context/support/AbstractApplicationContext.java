package org.springframework.context.support;

import org.springframework.beans.factory.BeanFactory;
import org.springframework.beans.factory.support.AbstractBeanFactory;
import org.springframework.beans.factory.support.DefaultListableBeanFactory;
import org.springframework.beans.factory.support.XmlBeanDefinitionReader;
import org.springframework.context.ApplicationContext;

import java.lang.annotation.Annotation;
import java.util.Map;

public abstract class AbstractApplicationContext implements ApplicationContext {

    //资源文件
    private String[] configLocations;

    //锁对象 用于启动与销毁
    private final Object startupShutdownMonitor = new Object();

    private DefaultListableBeanFactory beanFactory;

    public AbstractApplicationContext(String[] configLocations) {
        this.configLocations = configLocations;
    }

    public void refresh(){
        synchronized (this.startupShutdownMonitor){

            //创建容器
            refreshBeanFactory();
        }
    }

    protected void refreshBeanFactory(){
        if(hasBeanFactory()){
            destroyBeanFactory();
        }
        DefaultListableBeanFactory beanFactory =  new DefaultListableBeanFactory();
        loadBeanDefinitions(beanFactory);
        this.beanFactory = beanFactory;
    }
    protected void loadBeanDefinitions(DefaultListableBeanFactory beanFactory){
        if(configLocations != null){
            XmlBeanDefinitionReader reder = new XmlBeanDefinitionReader(beanFactory);
            reder.loadbeanDefinitions(configLocations);
        }
    }


    protected boolean hasBeanFactory(){
        return this.beanFactory != null;
    }

    protected void destroyBeanFactory() {
        this.beanFactory = null;
    }

    @Override
    public BeanFactory getParentBeanFactory() {
        return getBeanFactory().getParentBeanFactory();
    }

    @Override
    public <T> Map<String, T> getBeansOfType(Class<T> type) {
        return getBeanFactory().getBeansOfType(type);
    }

    @Override
    public Map<String, Object> getBeansWithAnnotation(Class<? extends Annotation> annotationType) {
        return getBeanFactory().getBeansWithAnnotation(annotationType);
    }

    @Override
    public Object getBean(String name) {
        return getBeanFactory().getBean(name);
    }

    protected AbstractBeanFactory getBeanFactory(){
         return this.beanFactory;
    }
}
