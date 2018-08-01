package org.springframework;

import javafx.application.Application;
import org.springframework.context.support.ClassPathXmlApplicationContext;

/**
 * Hello world!
 *
 */
public class MyMain
{
    private int snum = 0;

    public MyMain() {

    }

    public static void main(String[] args )
    {
        ClassPathXmlApplicationContext ca =
                new ClassPathXmlApplicationContext(
                        "E:\\study\\Spring\\spring-simple\\spring-demo\\src\\main\\resources\\applicationContext.xml");

//        ca.getBean("factory");
        System.out.print(((MyMain)ca.getBean("factory")).getNum());
    }

    public int getNum(){
        return this.snum;
    }
}
