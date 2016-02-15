package biz.poolparty.eu.council.utils;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import org.openrdf.model.Resource;
import org.openrdf.model.Statement;
import org.openrdf.model.URI;
import org.openrdf.model.Value;
import org.openrdf.rio.RDFHandlerException;
import org.openrdf.rio.helpers.RDFHandlerBase;

/**
 *
 * @author http://www.turnguard.com/turnguard
 */
public class StatementIndexer extends RDFHandlerBase {

    Map<Resource,Map<URI,Set<Value>>> data = new HashMap<>();
    public StatementIndexer(){}

    public Map<Resource,Map<URI,Set<Value>>> getStatementIndex(){
        return this.data;
    }
    
    @Override
    public void handleStatement(Statement st) throws RDFHandlerException {
        if(!data.containsKey(st.getSubject())){
            data.put(st.getSubject(), new HashMap<URI,Set<Value>>());
        }
        if(!data.get(st.getSubject()).containsKey(st.getPredicate())){
            data.get(st.getSubject()).put(st.getPredicate(), new HashSet<Value>());
        }
        data.get(st.getSubject()).get(st.getPredicate()).add(st.getObject());
    }
    
}
