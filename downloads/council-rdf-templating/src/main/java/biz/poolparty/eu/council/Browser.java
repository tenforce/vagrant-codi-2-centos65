package biz.poolparty.eu.council;

import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.servlet.http.HttpServletRequest;
import javax.annotation.Resource;
import org.openrdf.model.vocabulary.DCTERMS;
import org.openrdf.model.vocabulary.RDFS;
import org.openrdf.model.vocabulary.SKOS;
import org.openrdf.query.BindingSet;
import org.openrdf.query.MalformedQueryException;
import org.openrdf.query.QueryEvaluationException;
import org.openrdf.query.QueryLanguage;
import org.openrdf.query.QueryResults;
import org.openrdf.repository.Repository;
import org.openrdf.repository.RepositoryConnection;
import org.openrdf.repository.RepositoryException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.ModelAndView;

/**
 *
 * @author http://www.turnguard.com/turnguard
 */
@Controller
@RequestMapping("/browse")
public class Browser {

    @Resource
    private List<String> defaultListGraphs;

    @Autowired
    private String dataBaseURL;    
    
    private final String QUERY_LIST_RDF_SCHEMA_CLASSES = ""
            + "SELECT DISTINCT * "
            + "<defaultGraphs> "
            + "WHERE {"
            + " ?s a <"+RDFS.CLASS+">;"
            + "    <"+DCTERMS.TITLE+"> ?title;"
            + "    <"+DCTERMS.DESCRIPTION+"> ?description;"
            + "    <"+DCTERMS.IDENTIFIER+"> ?identifier"            
            + "} ORDER BY ?title";
    
    private final String QUERY_LIST_RDF_SCHEMA_CLASS_INSTANCES = ""
            + "SELECT DISTINCT * "
            + "<defaultGraphs> "
            + "WHERE {"
            + " ?s a <<rdfClass>>; "
            + "    <"+SKOS.PREF_LABEL+"> ?label . "
            + " OPTIONAL { ?s <"+SKOS.DEFINITION+"> ?definition }"
            + "} ORDER BY ?label LIMIT 10 OFFSET <offset>";
    
    private final String QUERY_COUNT_RDF_SCHEMA_CLASS_INSTANCES = ""
            + "SELECT (COUNT(DISTINCT ?s) AS ?count)"
            + "<defaultGraphs> "
            + "WHERE {"
            + " ?s a <<rdfClass>>"
            + "}";
    
    private final String QUERY_LIST_ACTS = ""
            + "SELECT DISTINCT ?act ?actTitle ?actDefinition "
            + "<defaultGraphs> "            
            + "WHERE { " 
            + " ?s ?p <<dimension>>; " 
            + "    a <http://purl.org/linked-data/cube#Observation>; " 
            + "    <<dataBaseURL>/data/public_voting/qb/dimensionproperty/act> ?act . "
            + " ?act <http://www.w3.org/2004/02/skos/core#prefLabel> ?actTitle; "
            + "      <http://www.w3.org/2004/02/skos/core#definition> ?actDefinition"            
            + "} ORDER BY ?act ?actTitle LIMIT 10 OFFSET <offset>";
    
    private final String QUERY_COUNT_ACTS = ""
            + "SELECT "
            + " (COUNT(DISTINCT ?act) AS ?count) "
            + "<defaultGraphs> "
            + "WHERE { " 
            + " ?s ?p <<dimension>>; " 
            + "    a <http://purl.org/linked-data/cube#Observation>;"
            + "    <<dataBaseURL>/data/public_voting/qb/dimensionproperty/act> ?act . " 
            + "} ";
    
    @Autowired
    private Repository repository;            
    
    public Browser(){}
    
    @RequestMapping(value="")
    public ModelAndView browseIndex(HttpServletRequest request) throws RepositoryException{
        ModelAndView mav = new ModelAndView("browse");
        RepositoryConnection repCon = null;
        try  {
            repCon = repository.getConnection();           
            
            mav.addObject("classes",this.getClasses(repCon));
            
            if(request.getParameter("rdfClass")!=null){                
                String instancesOffset = "0";
                if(request.getParameter("instancesOffset")!=null && !request.getParameter("instancesOffset").isEmpty()){
                    instancesOffset = request.getParameter("instancesOffset");
                }
                
                mav.addObject("instances",this.getInstances(repCon, request.getParameter("rdfClass"), instancesOffset));                
                mav.addObject("totalInstances", this.getTotalInstances(repCon, request.getParameter("rdfClass")));
                
                if(request.getParameter("dimension")!=null){
                    String actsOffset = "0";
                    if(request.getParameter("actsOffset")!=null && !request.getParameter("actsOffset").isEmpty()){
                        actsOffset = request.getParameter("actsOffset");
                    }
                    mav.addObject("acts", this.getActs(repCon, request.getParameter("dimension"), actsOffset));
                    mav.addObject("totalActs", this.getTotalActs(repCon, request.getParameter("dimension")));
                }                
            }            
        } finally {
            if(repCon!=null){
                try {
                    repCon.close();
                } catch(RepositoryException e){}
            }
        }        
        return mav;
    }

    private String defaultGraphList2From() {
	StringBuilder sb = new StringBuilder();
	String sep = "";
	String separator = " ";
	for(String graph: this.defaultListGraphs) {
	    sb.append(sep).append(String.format(" FROM <%s> ", graph));
	    sep = separator;
	}
	return sb.toString();                           
    }
    
    private List<BindingSet> getActs(RepositoryConnection repCon, String dimension, String offset){
        try {
	    System.out.println("QUERY:"+ 
			       QUERY_LIST_ACTS
                                        .replaceAll("<dimension>", dimension)
                                        .replaceFirst("<offset>", offset)
				        .replaceFirst("<defaultGraphs>", this.defaultGraphList2From())
			       .replaceAll("<dataBaseURL>", this.dataBaseURL));
            return QueryResults.asList(
                    repCon
                            .prepareTupleQuery(
                                    QueryLanguage.SPARQL,
                                    QUERY_LIST_ACTS
                                        .replaceAll("<dimension>", dimension)
                                        .replaceFirst("<offset>", offset)
				        .replaceFirst("<defaultGraphs>", this.defaultGraphList2From())
                                        .replaceAll("<dataBaseURL>", this.dataBaseURL)
                            ).evaluate()        
            );
        } catch (QueryEvaluationException | RepositoryException | MalformedQueryException ex) {
	    Logger.getLogger(Browser.class.getName()).log(Level.SEVERE, null, ex);
            return new ArrayList<>();
        }
    }
    
    private int getTotalActs(RepositoryConnection repCon, String dimension){
        try {
            return Integer.parseInt(
                    repCon
                            .prepareTupleQuery(
                                    QueryLanguage.SPARQL,
                                    QUERY_COUNT_ACTS
                                            .replaceAll(
                                                    "<dimension>",
                                                    dimension
                                            ).replaceFirst(
                                                    "<defaultGraphs>", 
                                                    this.defaultGraphList2From()
                                            ).replaceAll("<dataBaseURL>", this.dataBaseURL)
                            ).evaluate()
                            .next()
                            .getValue("count")
                            .stringValue()  
            );
        } catch (QueryEvaluationException | RepositoryException | MalformedQueryException ex) {
	    Logger.getLogger(Browser.class.getName()).log(Level.SEVERE, null, ex);
            return 0;
        }
    }
    
    private List<BindingSet> getClasses(RepositoryConnection repCon){
        try {
	    System.out.println("QUERY: " +
			       QUERY_LIST_RDF_SCHEMA_CLASSES
			       .replaceFirst(
					     "<defaultGraphs>", 
					     this.defaultGraphList2From()
					     ) );
            return QueryResults.asList(
                    repCon
                            .prepareTupleQuery(
                                    QueryLanguage.SPARQL,
                                    QUERY_LIST_RDF_SCHEMA_CLASSES
                                        .replaceFirst(
                                            "<defaultGraphs>", 
                                            this.defaultGraphList2From()
                                        )
                            ).evaluate()        
            );
        } catch (QueryEvaluationException | RepositoryException | MalformedQueryException ex) {
	    Logger.getLogger(Browser.class.getName()).log(Level.SEVERE, null, ex);
            return new ArrayList<>();
        }
    }
    
    private List<BindingSet> getInstances(RepositoryConnection repCon, String rdfClass, String offset){
        try {
            return QueryResults.asList(
                    repCon
                            .prepareTupleQuery(
                                    QueryLanguage.SPARQL,
                                    QUERY_LIST_RDF_SCHEMA_CLASS_INSTANCES
                                            .replaceAll(
                                                    "<rdfClass>",
                                                    rdfClass
                                            )
                                            .replaceFirst(
                                                    "<offset>",
                                                    offset
                                            ).replaceFirst(
                                                    "<defaultGraphs>", 
                                                    this.defaultGraphList2From()
                                            )
                            ).evaluate()    
            );
        } catch (QueryEvaluationException | RepositoryException | MalformedQueryException ex) {
	    Logger.getLogger(Browser.class.getName()).log(Level.SEVERE, null, ex);
            return new ArrayList<>();
        }
    }
    
    private int getTotalInstances(RepositoryConnection repCon, String rdfClass){
        try {
            return Integer.parseInt(
                    repCon
                            .prepareTupleQuery(
                                    QueryLanguage.SPARQL,
                                    QUERY_COUNT_RDF_SCHEMA_CLASS_INSTANCES
                                            .replaceAll(
                                                    "<rdfClass>",
                                                    rdfClass
                                            ).replaceFirst(
                                                    "<defaultGraphs>", 
                                                    this.defaultGraphList2From()
                                            )
                            ).evaluate()
                            .next()
                            .getValue("count")
                            .stringValue()  
            );
        } catch (QueryEvaluationException | RepositoryException | MalformedQueryException ex) {
	    Logger.getLogger(Browser.class.getName()).log(Level.SEVERE, null, ex);
            return 0;
        }
    }
    
}
