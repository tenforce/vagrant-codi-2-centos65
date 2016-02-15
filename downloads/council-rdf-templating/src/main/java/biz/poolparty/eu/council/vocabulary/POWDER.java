package biz.poolparty.eu.council.vocabulary;

import org.openrdf.model.URI;
import org.openrdf.model.impl.URIImpl;

/**
 *
 * @author http://www.turnguard.com/turnguard
 */
public class POWDER {
    public static final String NAMESPACE = "http://www.w3.org/2007/05/powder-s#";
    
    public static final URI DESCRIBED_BY = new URIImpl(NAMESPACE.concat("describedBy"));
}
