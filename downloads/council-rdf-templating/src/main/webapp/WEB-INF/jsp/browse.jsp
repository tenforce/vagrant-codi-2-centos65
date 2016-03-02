<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %><%@page contentType="application/xhtml+xml" pageEncoding="UTF-8"%><?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML+RDFa 1.1//EN" "http://www.w3.org/MarkUp/DTD/xhtml-rdfa-2.dtd">
<html 
        xmlns="http://www.w3.org/1999/xhtml"
        xmlns:foaf="http://xmlns.com/foaf/0.1/"
        xmlns:wdrs="http://www.w3.org/2007/05/powder-s#"
        xmlns:contact="http://www.w3.org/2000/10/swap/pim/contact#">
    <head>
        <meta http-equiv="Content-Type" content="application/xhtml+xml; charset=UTF-8"/>
        <title>data.consilium.europa.eu</title>
        <link rel="stylesheet" href="/resources/fontawesome/css/font-awesome.min.css"/>
        <link rel="stylesheet" href="/resources/css/style.css"/>
    </head>
    <body>       
        <jsp:include page="header.jsp" flush="true"/>
        <div id="dataContainer">
            <h2>TF: Council votes on legislative acts</h2>
            <h3>Browse dataset</h3>
            <p><b>License:</b> Legal Notice Consilium, see: <a href="http://www.consilium.europa.eu/en/about-site/legal-notice/" target="_blank">http://www.consilium.europa.eu/en/about-site/legal-notice/</a></p>
            <ul class="link-list">
                <li><a href="http://data.consilium.europa.eu/data/public-voting/council-votes-on-legislative-acts.zip">Download complete dataset</a></li>
            </ul>
            <p>Browse dataset by:</p>            
            <ul class="link-list" style="float:left">                
            <c:choose>
                    <c:when test="${not empty param.instancesOffset}">
                            <c:set var="instancesOffset" value="${param.instancesOffset}"/>
                    </c:when>
                    <c:otherwise>
                            <c:set var="instancesOffset" value="0"/>
                    </c:otherwise>
            </c:choose>

            <c:forEach var="bindingSet" items="${classes}">
                    <c:choose>
                            <c:when test="${bindingSet.getValue('s').stringValue() eq param.rdfClass}">
                                    <c:set var="fontStyle" value="font-weight:bold;"/>
                            </c:when>
                            <c:otherwise>
                                    <c:set var="fontStyle" value=""/>
                            </c:otherwise>
                    </c:choose>
                    <li>
                        <a href="?rdfClass=${bindingSet.getValue('s')}" style="${fontStyle}">${bindingSet.getValue('title').stringValue()}</a>
                    </li>
            </c:forEach>
            </ul>    
            <!-- INSTANCES OF CHOSEN CLASS START -->
            <%
                int perPage = 10;
                int total = -1;
                int offset = -1;
            %>
            <c:if test="${not empty instances}">                    
                    <ul class="link-list" style="margin-left:20px;float:left;max-width:200px;">                                        
                    <c:forEach var="bindingSet" items="${instances}">
                            <c:choose>
                                <c:when test="${bindingSet.getValue('s').stringValue() eq param.dimension}">
                                    <c:set var="fontStyle" value="font-weight:bold;"/>
                                </c:when>
                                <c:otherwise>
                                    <c:set var="fontStyle" value=""/>
                                </c:otherwise>
                            </c:choose>
                            <li>
                            <a href="?dimension=${bindingSet.getValue('s').stringValue()}&amp;rdfClass=${param.rdfClass}&amp;instancesOffset=${instancesOffset}" style="${fontStyle}">
                                    ${bindingSet.getValue('label').stringValue()}
                            </a>
                            </li>
                    </c:forEach>
                    <br/>
                    <%
                    total = (Integer)request.getAttribute("totalInstances");
                    offset = request.getParameter("instancesOffset")!=null?Integer.parseInt(request.getParameter("instancesOffset")):0;
                    if(total>perPage){
                            if(offset>0){
                                    %>
                                    <a href="?rdfClass=<%=request.getParameter("rdfClass")%>">First</a>
                                    <a href="?rdfClass=<%=request.getParameter("rdfClass")%>&amp;instancesOffset=<%=(offset-perPage)%>">Previous</a>
                                    <%
                            }
                            if((offset+perPage)<total){
                                    %>
                                    <a href="?rdfClass=<%=request.getParameter("rdfClass")%>&amp;instancesOffset=<%=(offset+perPage)%>">Next</a>
                                    <a href="?rdfClass=<%=request.getParameter("rdfClass")%>&amp;instancesOffset=<%=((int)Math.floor(total/perPage)*perPage)%>">Last</a>
                                    <%
                            }
                            out.print(" (Total:"+total+")");	
                    }
                    %>
                    </ul>
            </c:if> 
            <!-- INSTANCES OF CHOSEN CLASS END -->
            <!-- ACTS FOR CHOSEN INSTANCE START -->
            <c:if test="${not empty acts}">
                    <ul class="link-list" style="margin-left:20px;float:left;max-width:600px;">                        
                    <c:forEach var="acts" items="${acts}">
                        <li>
                            <a href="${acts.getValue('act').stringValue()}" target="_blank">${acts.getValue('actTitle').stringValue()}</a>
                            ${acts.getValue('actDefinition').stringValue()}
                        </li>
                    </c:forEach>
                    <br/>
                    <%
                    total = (Integer)request.getAttribute("totalActs");
		    offset = request.getParameter("actsOffset")!=null?Integer.parseInt(request.getParameter("actsOffset")):0;
                    if(total>perPage){
                            if(offset>0){
                                   %>
                                   <a href="?rdfClass=${param.rdfClass}&amp;dimension=${param.dimension}&amp;instancesOffset=${param.instancesOffset}">First</a>
                                   <a href="?rdfClass=${param.rdfClass}&amp;dimension=${param.dimension}&amp;instancesOffset=${param.instancesOffset}&amp;actsOffset=<%=(offset-perPage)%>">Previous</a>
                                   <%
                            }
                            if((offset+perPage)<total){
                            %>
                            <a href="?rdfClass=${param.rdfClass}&amp;dimension=${param.dimension}&amp;instancesOffset=${param.instancesOffset}&amp;actsOffset=<%=(offset+perPage)%>">Next</a>
                            <a href="?rdfClass=${param.rdfClass}&amp;dimension=${param.dimension}&amp;instancesOffset=${param.instancesOffset}&amp;actsOffset=<%=((int)Math.floor(total/perPage)*perPage)%>">Last</a>
                            <%
                            }
                            out.print(" (Total:"+total+")");
                            }
                    %>
                    </ul>
            </c:if>            
        <jsp:include page="relatedLinks.jsp" flush="true"/>

        </div>
	<br style="clear:left"/>
        <jsp:include page="footer.jsp" flush="true"/>
    </body>
</html>
