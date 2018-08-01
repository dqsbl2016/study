package org.springframework.beans.factory.support;

import org.springframework.beans.factory.BeanDefinition;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;

public class XmlBeanDefinitionReader extends AbstractBeanDefinitionReader {

    private DefaultListableBeanFactory beanFactory;

    public XmlBeanDefinitionReader(DefaultListableBeanFactory beanFactory) {
        this.beanFactory = beanFactory;
    }

    public int doLoadBeanDefinition(String location){
        try{
            DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
            DocumentBuilder dbr = dbf.newDocumentBuilder();
            File file = new File(location);

            Document document = dbr.parse(file);
            BeanDefinition beanDefinition =  parse(document);
            if(beanDefinition != null){
                return registerBeanDefinitions(beanDefinition);
            }else{
                return 0;
            }
        }catch (Exception e){

        }
        return 0;
    }

    public BeanDefinition parse(Document document){
        Element root = document.getDocumentElement();
        NodeList nl = root.getChildNodes();
        for(int i=0;i<nl.getLength();i++){
            Node node = nl.item(i);
            if (node instanceof Element) {
                Element ele = (Element) node;
                if ( (ele.getNodeName().equals("bean") || ele.getLocalName().equals("bean"))) {
                    String id = ele.getAttribute("id");
                    String nameAttr = ele.getAttribute("name");
                    String beanclass = ele.getAttribute("class");
                    GenericBeanDefinition genericBeanDefinition = new GenericBeanDefinition();
                    genericBeanDefinition.setBeanClassName(nameAttr);
                    genericBeanDefinition.setBeanClass(beanclass);
                    return genericBeanDefinition;
                }
            }
        }
        return null;
    }

    public int registerBeanDefinitions(BeanDefinition beanDefinition){
        this.beanFactory.registerBeanDefinition(beanDefinition);
        return 1;
    }
}
