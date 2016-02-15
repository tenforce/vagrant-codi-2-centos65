package biz.poolparty.eu.council;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileReader;
import java.io.IOException;
import java.util.zip.ZipOutputStream;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.apache.commons.io.IOUtils;
import org.openrdf.repository.RepositoryException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

/**
 *
 * @author http://www.turnguard.com/turnguard
 */
@Controller
@RequestMapping("/download")
public class Downloader {
            
    @Autowired
    private String downloadFileTurtle;
    
    @Autowired
    private String downloadFileZip;    
    
    public Downloader(){}
    
    @RequestMapping(value="/turtle")
    public void downloadTurtle(HttpServletResponse response) throws IOException, RepositoryException {
        File f = new File(this.downloadFileTurtle);
        response.setContentType("text/turtle");
        response.setHeader("Content-Disposition", "attachment; filename="+f.getName());
        IOUtils.copyLarge(new FileReader(f), response.getWriter());
        response.flushBuffer();
    }
    @RequestMapping(value="/zip")
    public void downloadZip(HttpServletResponse response, HttpServletRequest request) throws IOException, RepositoryException {        
        File f = new File(this.downloadFileZip);
        response.reset();
        //response.setHeader("filename", f.getAbsolutePath());
        //response.setContentType("application/zip");
        response.setHeader("Content-Disposition", "attachment; filename="+f.getName());
        IOUtils.copy(new FileReader(f), response.getOutputStream()); 
        response.flushBuffer();
        
    }    
}
