package org.springframework.beans.factory;

import java.lang.annotation.Annotation;
import java.util.Map;

/*
     获取Bean的集合，一次获取全部Bean 而不是一个bean
 */
public interface ListableBeanFactory extends BeanFactory {

    //通过类别获取所有Beans
    <T> Map<String, T> getBeansOfType(Class<T> type);

    //通过指定注解所有Beans
    Map<String, Object> getBeansWithAnnotation(Class<? extends Annotation> annotationType);
}
