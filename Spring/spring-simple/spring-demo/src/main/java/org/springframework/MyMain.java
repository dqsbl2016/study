package org.springframework;

import javafx.application.Application;
import org.springframework.beans.annotion.AutoWired;
import org.springframework.beans.annotion.Controller;
import org.springframework.context.support.ClassPathXmlApplicationContext;

/**
 * Hello world!
 *
 */
@Controller
public class MyMain
{
    private int snum = 0;

    @AutoWired
    private Car cars;

    public MyMain() {

    }

    public static void main(String[] args )
    {
        ClassPathXmlApplicationContext ca =
                new ClassPathXmlApplicationContext(
                        "E:\\study\\Spring\\spring-simple\\spring-demo\\src\\main\\resources\\applicationContext.xml");

        MyMain my = (MyMain)ca.getBean("factory");
        System.out.print(my.getNum());

    }

    public int getNum(){
       System.out.println(cars.get());
        return this.snum;
    }
}
