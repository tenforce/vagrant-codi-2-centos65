package biz.poolparty.eu.council;

import biz.poolparty.eu.council.utils.StatementIndexer;
import biz.poolparty.eu.council.vocabulary.FOAF;
import biz.poolparty.eu.council.vocabulary.POWDER;
import java.util.ArrayList;
import java.util.List;
import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.annotation.Resource;
import org.openrdf.model.Statement;
import org.openrdf.model.URI;
import org.openrdf.model.impl.StatementImpl;
import org.openrdf.model.impl.URIImpl;
import org.openrdf.model.vocabulary.RDF;
import org.openrdf.query.MalformedQueryException;
import org.openrdf.query.QueryEvaluationException;
import org.openrdf.query.QueryLanguage;
import org.openrdf.repository.Repository;
import org.openrdf.repository.RepositoryConnection;
import org.openrdf.repository.RepositoryException;
import org.openrdf.rio.RDFFormat;
import org.openrdf.rio.RDFHandler;
import org.openrdf.rio.RDFHandlerException;
import org.openrdf.rio.Rio;
import org.openrdf.rio.helpers.RDFHandlerBase;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;

/**
 *
 * @author http://www.turnguard.com/turnguard
 */
@Controller
@RequestMapping("/dereference")
public class Dereferencer {

    @Resource
    private List<String> defaultListGraphs;

    private final String DEFAULT_DEREFERENCE_QUERY_TPL = ""
            + "CONSTRUCT "
            + "{ "
            + " <<entity>> ?p ?o . "
            + " ?o ?a ?b "
	    + "} <defaultGraphs> WHERE { "
            + " <<entity>> ?p ?o . "
            + "OPTIONAL { ?o ?a ?b FILTER(isBlank(?o)) } "
            + "}";
    
    @Autowired
    private Repository repository;            
    
    public Dereferencer(){}
    
    @RequestMapping(value="", params={ "uri", "ext" }, headers={ "accept=application/xhtml+xml", "accept=text/html" })
    public ModelAndView dereferenceToHTML(HttpServletResponse response, @RequestParam String uri, @RequestParam String ext) throws IOException, RepositoryException {
        ModelAndView mav = new ModelAndView("entity");
        URI entity = new URIImpl(uri.replaceFirst(".".concat(ext), ""));        
        URI document = new URIImpl(uri);   
        StatementIndexer handler = new StatementIndexer();
        RepositoryConnection repCon = null;
        try  {
            repCon = repository.getConnection();
            repCon.prepareGraphQuery(
                    QueryLanguage.SPARQL, 
                    DEFAULT_DEREFERENCE_QUERY_TPL
                            .replaceAll("<entity>", entity.stringValue())
		            .replaceFirst("<defaultGraphs>", this.defaultGraphList2From())
            ).evaluate(new WDRSRDFHandler(handler, entity, document));
            mav.addObject("res", handler.getStatementIndex());
        } catch (QueryEvaluationException ex) {
            Logger.getLogger(Dereferencer.class.getName()).log(Level.SEVERE, null, ex);
        } catch (RDFHandlerException ex) {
            Logger.getLogger(Dereferencer.class.getName()).log(Level.SEVERE, null, ex);
        } catch (MalformedQueryException ex) {
            Logger.getLogger(Dereferencer.class.getName()).log(Level.SEVERE, null, ex);
        } finally {
            if(repCon!=null){
                try {
                    repCon.close();
                } catch(RepositoryException e){}
            }
        }
        return mav;        
    }
    
    @RequestMapping(value="", params={ "uri", "ext" }, headers={ "accept=application/rdf+xml", "accept=text/turtle" })
    public void dereferenceToRDF(HttpServletRequest request, HttpServletResponse response, @RequestParam String uri, @RequestParam String ext) throws RepositoryException, IOException{
        URI entity = new URIImpl(uri.replaceFirst(".".concat(ext), ""));        
        URI document = new URIImpl(uri);
        RDFFormat rdfFormat = this.getWriterFormat(request.getHeader("accept"));
        response.setContentType(rdfFormat.getDefaultMIMEType());
        RepositoryConnection repCon = null;
        try  {
            repCon = repository.getConnection();
            try {                
                repCon.prepareGraphQuery(
                        QueryLanguage.SPARQL, 
                        DEFAULT_DEREFERENCE_QUERY_TPL
                                .replaceAll("<entity>", entity.stringValue())
			.replaceFirst("<defaultGraphs>", this.defaultGraphList2From())

                )
                        .evaluate(
                                new WDRSRDFHandler(
                                        Rio.createWriter(
                                                rdfFormat, 
                                                response.getWriter()
                                        ), entity, document)
                        );
            } catch (QueryEvaluationException ex) {
                Logger.getLogger(Dereferencer.class.getName()).log(Level.SEVERE, null, ex);
            } catch (RDFHandlerException ex) {
                Logger.getLogger(Dereferencer.class.getName()).log(Level.SEVERE, null, ex);
            } catch (MalformedQueryException ex) {
                Logger.getLogger(Dereferencer.class.getName()).log(Level.SEVERE, null, ex);
            }
        } finally {
            if(repCon!=null){
                try {
                    repCon.close();
                } catch(RepositoryException e){}
            }
        }        
    }
    
    private String defaultGraphList2From() {
	StringBuilder sb = new StringBuilder();
	String sep = "";
	String separator = " ";
	for(String graph : this.defaultListGraphs) {
	    sb.append(sep).append(String.format(" FROM <%s> ", graph));
	    sep = separator;
	}
	return sb.toString();                           
    }
    
    private RDFFormat getWriterFormat(String acceptHeader){
        acceptHeader = acceptHeader.trim();
        if(acceptHeader.equals("*/*") || acceptHeader.equals("text/turtle")){
            return RDFFormat.TURTLE;
        }
        if(acceptHeader.equals("application/rdf+xml")){
            return RDFFormat.RDFXML;
        }
        return RDFFormat.TURTLE;
    }
    
    private class WDRSRDFHandler extends RDFHandlerBase {
        private int numStates = 0;
        private final RDFHandler baseHandler;
        private final URI entity;
        private final URI document;
        public WDRSRDFHandler(RDFHandler baseHandler, URI entity, URI document){
            this.baseHandler = baseHandler;
            this.entity = entity;
            this.document = document;
        }

        @Override
        public void startRDF() throws RDFHandlerException {
            this.baseHandler.startRDF();
        }        

        @Override
        public void handleNamespace(String prefix, String uri) throws RDFHandlerException {
            this.baseHandler.handleNamespace(prefix, uri);
        }
        
        @Override
        public void handleStatement(Statement st) throws RDFHandlerException {
            this.numStates++;
            this.baseHandler.handleStatement(st);
        }

        @Override
        public void endRDF() throws RDFHandlerException {
            if(this.numStates==0){
                throw new RDFHandlerException("404");
            }
            this.handleStatement(new StatementImpl(entity, POWDER.DESCRIBED_BY, document));
            this.handleStatement(new StatementImpl(document, RDF.TYPE, FOAF.DOCUMENT));
            this.handleStatement(new StatementImpl(document, FOAF.PRIMARY_TOPIC, entity));
            this.baseHandler.endRDF();
        }
    }
}
