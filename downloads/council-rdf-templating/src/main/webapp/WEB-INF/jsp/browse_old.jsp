<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %><%@page contentType="application/xhtml+xml" pageEncoding="UTF-8"%><?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML+RDFa 1.1//EN" "http://www.w3.org/MarkUp/DTD/xhtml-rdfa-2.dtd">
<html 
        xmlns="http://www.w3.org/1999/xhtml"
        xmlns:foaf="http://xmlns.com/foaf/0.1/"
        xmlns:wdrs="http://www.w3.org/2007/05/powder-s#"
        xmlns:contact="http://www.w3.org/2000/10/swap/pim/contact#">
    <head>
        <meta http-equiv="Content-Type" content="application/xhtml+xml; charset=UTF-8"/>
        <title>data.consilium.eu</title>
        <link href='http://fonts.googleapis.com/css?family=Open+Sans:400,300,300italic,400italic,600,600italic,700,700italic,800,800italic' rel='stylesheet' type='text/css' />        
        <style type="text/css">
        html { padding: 0; }
        body {
            color: #3f4a52;
            font-family: "Open Sans",Arial,Tahoma,sans-serif;
            font-size: 70%;
            line-height: 1.6;
            margin:0;
            transition-delay: 0.25s;
            transition-duration: 0.25s;
            transition-property: font-size;
        }

        a, a:link {
            color: #164194;
            text-decoration: none;
        }

        a:hover, a:active, a:focus {
            text-decoration: underline;
        }
        #header {
                padding-top: 28px;
                position: relative;
                width: 70.9402%;
                margin:0 auto;
        }
        .logo {
                display: inline-block;
                vertical-align: bottom;
        }

        img {
            border: 0 none;
            height: auto;
            max-width: 100%;
            vertical-align: middle;
        }

        #header .logo-slogan {
            color: #666;
            display: inline-block;
            font-family: Arial,"Open Sans",Tahoma,sans-serif;
            font-weight: bold;
            margin-left: 24px;
            position: relative;
            top: 0.5em;
            vertical-align: bottom;
        }

        #header .title-h1 {
            color: #666;
            font-size: 19px;
            line-height: 150%;
        }

        #header h1 {
            border-bottom: 1px solid #ccc;
            color: #164194;
            font-size: 35px;
            font-weight: bold;
            margin: 34px 0 20px;
            padding-bottom: 11px;
            text-align: left;
        }

        #headerAlternatives {
                font-weight:bold;
        }

        #headerAlternatives a{text-decoration: underline;}

        #dataContainer {
		  margin: 0 auto;
        width: 70.9402%;
        }

        #footer {
            margin-top: 40px;
        }

        #footer .footer-links {
            background: none repeat scroll 0 0 #e2ebed;
        }

        #footer .footer-links ul {
            margin-bottom: 0;
            padding: 0 14.5299%;
        }
        #footer .footer-links ul, #footer .footer-nav .navbar-inner {
            padding: 0 5%;
        }

        #footer p.copyright {
            color: #777;
            font-size: 80%;
            margin: 0;
            padding: 10px 5%;
        }

        ul.inline, ol.inline {
            list-style: outside none none;
            margin-left: 0;
        }

        ul > li, ol > li {
            line-height: 1.6;
            margin-bottom: 0;
        }

        #footer .footer-links li {
            border-right: 1px solid #346195;
            display: inline-block;
            padding-left: 10px;
            padding-right: 15px;
            vertical-align: middle;
        }

        #footer .footer-links ul li.first {
            max-width: 60px;
            padding: 10px 0;
        }

        #footer .footer-links figure {
            margin: 0;
            padding: 0;
        }

        #footer .footer-links li.first {
            border: medium none;
        }

        #footer .footer-links ul li.second {
            font-weight: bold;
        }

        #footer .footer-links ul li.third {
            border-right: medium none;
            padding-right: 5px;
        }

        #footer .footer-links ul li.last {
            border: medium none;
        }

	.subject {margin:20px 0;}
        .predicate {
		padding-left:40px;
	}
        .object {
                padding-left:40px;
        }
        </style>
    </head>
    <body>
        <div id="header">
            <div class="logo-wrapper">
                <div class="logo">
                    <img width="97" height="82" id="logo" src="<c:url value="/resources/images/logo.png" />" />
                </div>
                <div class="logo-slogan">
                    <div class="title-h1 ec">European Council</div>
                    <div class="title-h1 cote">Council of the European Union</div>
                </div>
            </div>
            <h1 id="headerUri">BROWSE</h1>
            <div id="headerAlternatives">
		<a href="public_voting/download">Download Dataset</a>
            </div> 
        </div> 
        <div id="dataContainer">
                <div style="float:left">
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
                        <a href="?rdfClass=${bindingSet.getValue('s')}" style="${fontStyle}">${bindingSet.getValue('title').stringValue()}</a><br/>
                </c:forEach>
                </div>
		<c:if test="${not empty instances}">
	                <div style="margin-left:20px;float:left;max-width:200px;">
        	        <c:forEach var="bindingSet" items="${instances}">
				<c:choose>
				    <c:when test="${bindingSet.getValue('s').stringValue() eq param.dimension}">
				        <c:set var="fontStyle" value="font-weight:bold;"/>
				    </c:when>
				    <c:otherwise>
                                        <c:set var="fontStyle" value=""/>
				    </c:otherwise>
				</c:choose>
                	        <a href="?dimension=${bindingSet.getValue('s').stringValue()}&amp;rdfClass=${param.rdfClass}&amp;instancesOffset=${instancesOffset}" style="${fontStyle}">
					${bindingSet.getValue('label').stringValue()}
				</a>
				<br/>
                	</c:forEach>
			<br/>
			<%
			int perPage = 10;
			int total = (Integer)request.getAttribute("totalInstances");
			int offset = request.getParameter("instancesOffset")!=null?Integer.parseInt(request.getParameter("instancesOffset")):0;
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
			</div>
		</c:if>
		<c:if test="${not empty acts}">
			<div style="margin-left:20px;float:left;max-width:600px;">
        	        <c:forEach var="acts" items="${acts}">
                	        <a href="${acts.getValue('act').stringValue()}" target="_blank">${acts.getValue('actTitle').stringValue()}</a>
				${acts.getValue('actDefinition').stringValue()}
				<br/>
                	</c:forEach>
			<br/>
                        <%
                        int perPage = 10;
                        int total = (Integer)request.getAttribute("totalActs");
                        int offset = request.getParameter("actsOffset")!=null?Integer.parseInt(request.getParameter("actsOffset")):0;
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
			</div>
		</c:if>
                <br style="clear:left"/>
        </div>
        <div id="footer">
            <div class="footer-links inner-full">
                <ul class="inline">
                    <li class="first">
                        <figure>
                            <img alt="UE flag" src="<c:url value="/resources/images/img_flag-eu.png" />" />
                        </figure>
                    </li>
                    
                    <li class="second">
                        <a href="http://europa.eu/index_en.htm">European Union</a>
                    </li>
                        
                    <li class="third">
                        <a href="http://www.europarl.europa.eu/portal/en">European Parliament</a>
                    </li>
                        
                    <li class="last">
                        <a href="http://ec.europa.eu/index_en.htm">European Commission</a>
                    </li>
                        
                </ul>
            </div>
        </div>
    </body>
</html>
