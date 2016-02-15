package biz.poolparty.eu.council.vocabulary;

import org.openrdf.model.URI;
import org.openrdf.model.impl.URIImpl;

/**
 *
 * @author http://www.turnguard.com/turnguard
 */
public class FOAF {
    public static final String NAMESPACE = "http://xmlns.com/foaf/0.1/";
    
    public static final URI DOCUMENT = new URIImpl(NAMESPACE.concat("Document"));
    public static final URI PRIMARY_TOPIC = new URIImpl(NAMESPACE.concat("primaryTopic"));
}
