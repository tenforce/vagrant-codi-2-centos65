<%-- 
    Document   : header
    Created on : Mar 6, 2015, 11:21:37 AM
    Author     : turnguard
--%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<div id="header">
    <div class="logo-wrapper">
        <div class="logo">
            <img width="97" height="82" id="logo" src="/static/resources/images/logo.png" />
        </div>
        <div class="logo-slogan">
            <div class="title-h1 ec">European Council</div>
            <div class="title-h1 cote">Council of the European Union</div>
        </div>
    </div>
    <c:choose>
            <c:when test="${not empty classes}">
                <h1 id="headerUri">OpenData - Public Voting - Browsing</h1>
            </c:when>
            <c:otherwise>
                <h1 id="headerUri">OpenData - Public Voting</h1>
            </c:otherwise>
    </c:choose>    
    <div class="specialspan2 hgrouptags">
        <div class="hgp">
            <div class="inner-institution">
                <span class="short-heading gsc">
                    <span>General Secretariat</span>
                    <span class="color-institution"></span>
                </span>
            </div>
        </div>
        <div class="content gsc noheader-nofooter-page noh-nof-page nav-buttons row-fluid">
            <div class="span6 content-center">
                <div id="ctl00_cpMain_divBackToOverview" class="content-top nav-center-button">
                <c:choose>
                        <c:when test="${not empty classes}">
                            <a class="meeting-button backto" href="http://www.consilium.europa.eu/en/general-secretariat/corporate-policies/transparency/open-data/">
                                <span class="hide-mobile">Back to overview</span>
                            </a>
                        </c:when>
                        <c:otherwise>
                            <a class="meeting-button backto" href="http://www.consilium.europa.eu/en/documents-publications/">
                                <span class="hide-mobile">Back to overview</span>
                            </a>
                        </c:otherwise>
                </c:choose>                     

                </div>
            </div>
        </div>
    </div>
</div>
