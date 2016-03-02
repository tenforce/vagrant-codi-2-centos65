<%@page import="org.openrdf.model.URI"%><%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %><%@page contentType="application/xhtml+xml" pageEncoding="UTF-8"%><?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML+RDFa 1.1//EN" "http://www.w3.org/MarkUp/DTD/xhtml-rdfa-2.dtd">
<html 
        xmlns="http://www.w3.org/1999/xhtml"
        xmlns:foaf="http://xmlns.com/foaf/0.1/"
        xmlns:wdrs="http://www.w3.org/2007/05/powder-s#"
        xmlns:contact="http://www.w3.org/2000/10/swap/pim/contact#">
    <head>
        <meta http-equiv="Content-Type" content="application/xhtml+xml; charset=UTF-8"/>
        <title>data.consilium.europa.eu</title>
        <link rel="stylesheet" href="/resources/css/fontawesome/css/font-awesome.min.css"/>
        <link rel="stylesheet" href="/resources/css/style.css"/>
    </head>
    <body> 
        <jsp:include page="header.jsp" flush="true"/>
        <div id="dataContainer">
            <h2>TF: <%=request.getParameter("uri").replaceFirst(".".concat(request.getParameter("ext")),"")%></h2>        
            <div id="headerAlternatives">
                <a target="_blank" href="<%=request.getParameter("uri").replaceFirst(".".concat(request.getParameter("ext")),".ttl")%>">turtle</a>
                <a target="_blank" href="<%=request.getParameter("uri").replaceFirst(".".concat(request.getParameter("ext")),".rdf")%>">rdfxml</a>
                <a target="_blank" href="/sparql?query=SELECT * WHERE { &lt;<%=request.getParameter("uri").replaceFirst(".".concat(request.getParameter("ext")),"")%>&gt; ?p ?o }">sparql</a>                
            </div>            
            <c:forEach var="subject" items="${res}">
                <div class="subject" about="${subject.key}">${subject.key}
                <c:forEach var="predicate" items="${subject.value}">
                    <c:set var="headerWritten" value="false"/>                        
                        <c:forEach var="object" items="${predicate.value}">
                            <c:choose>
                                <c:when test='<%=(pageContext.getAttribute("object") instanceof URI)%>'>
                                    <c:if test="${headerWritten==false}">
                                        <div class="predicate">
                                            <a href="${predicate.key}">${predicate.key}</a>
                                        <c:set var="headerWritten" value="true"/>
                                    </c:if>
                                    <div class="object" rel="${predicate.key}"><a href="${object.stringValue()}">${object.stringValue()}</a></div>
                                </c:when>
                                <c:otherwise> 
                                    <c:if test="${headerWritten==false}">
                                        <div class="predicate">
                                            <a href="${predicate.key}">${predicate.key}</a>
                                        <c:set var="headerWritten" value="true"/>
                                    </c:if>                                
                                    <div class="object" property="${predicate.key}" content="${object.stringValue()}">${object.stringValue()}</div>
                                </c:otherwise>
                            </c:choose>
                        </c:forEach>
                        </div>
                </c:forEach>
                </div>
            </c:forEach>
        <jsp:include page="relatedLinks.jsp" flush="true"/>
        </div>
	<br style="clear:left"/>
        <jsp:include page="footer.jsp" flush="true"/>           
    </body>
</html>