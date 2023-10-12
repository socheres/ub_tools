<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:mods="http://www.loc.gov/mods/v3"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:marc="http://www.loc.gov/MARC21/slim"
    exclude-result-prefixes="mods xlink marc">

    
    <xsl:include href="MARC21slimUtils-pts.xsl"/>
    
    <xsl:output method="xml" indent="yes" encoding="UTF-8" omit-xml-declaration="no"/>
    
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="mods:modsCollection">
        <marc:collection xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
            <xsl:apply-templates/>
        </marc:collection>
    </xsl:template>

    <xsl:template match="*"/>
    
    <xsl:strip-space  elements="*"/>
    
    <xsl:template match="mods:mods">
        <collection xmlns="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
            <record>
                <xsl:choose>
                    <xsl:when test="parent::mods:modsCollection"/>
                    <xsl:otherwise>
                        <xsl:text></xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
                <leader>
                    <xsl:value-of select="//*[local-name()='leader']/text()"/>
                </leader>
                <xsl:if test="//*[@tag='001']/text()">
                    <controlfield tag="001">
                        <xsl:value-of select="//*[@tag='001']/text()"/>
                    </controlfield>
                </xsl:if>
                <xsl:choose>
                    <!-- Dieses Feld kommt 12001 mal vor, aber wird durch "DE-Tue135" überschrieben -->
                    <xsl:when test="//*[@tag='003']/text()">
                        <controlfield tag="003">DE-Tue135</controlfield>
                    </xsl:when>
                    <xsl:otherwise>
                        <controlfield tag="003">DE-Tue135</controlfield>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="//*[@tag='005']/text()">
                    <controlfield tag="005">
                        <xsl:value-of select="//*[@tag='005']/text()"/>
                    </controlfield>
                </xsl:if>
                
                <xsl:if test="//*[@tag='007']/text()">   
                    <controlfield tag="007">
                        <xsl:value-of select="//*[@tag='007']/text()"/>
                    </controlfield>
                </xsl:if>
                <xsl:if test="//*[@tag='008']/text()">
                    <controlfield tag="008">
                        <xsl:value-of select="//*[@tag='008']/text()"/>
                    </controlfield>
                </xsl:if>
                <!-- references https://www.loc.gov/marc/bibliographic/bd028.html https://www.oclc.org/bibformats/en/0xx/019.html -->
                <!-- 010 - Library of Congress Control Number (NR)  -->
                <xsl:if test="//*[@tag='010']">
                    <xsl:for-each select="//*[@tag='010'][local-name(*[1])='subfield']">
                        <datafield tag="010" ind1=" " ind2=" ">
                            <xsl:apply-templates select="*[1]"/>
                            <xsl:apply-templates select="*[position()>1]"/>
                        </datafield>
                    </xsl:for-each>
                </xsl:if>
    
                <!-- 020 - International Standard Book Number (R)  -->
                <xsl:if test="//*[@tag='020']">
                    <xsl:for-each select="//*[@tag='020'][local-name(*[1])='subfield']">
                        <datafield tag="020" ind1=" " ind2=" ">
                            <xsl:apply-templates select="*[1]"/>
                            <xsl:apply-templates select="*[position()>1]"/>
                        </datafield>
                    </xsl:for-each>
                </xsl:if>     
                <!-- 022 - International Standard Serial Number (R) -->
                <xsl:if test="//*[@tag='022']">
                    <xsl:for-each select="//*[@tag='022'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">022</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 028 - Publisher or Distributor Number (R) subfield a, b, 6 (NR) q, 8 (R) -->            
                <xsl:if test="//*[@tag='028']">
                    <xsl:for-each select="//*[@tag='028'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">028</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 035 - System Control Number (R) -->
                <xsl:if test="//*[@tag='035']">
                    <xsl:for-each select="//*[@tag='035'][local-name(*[1])='subfield']">
                        <datafield tag="035" ind1=" " ind2=" ">            
                            <xsl:apply-templates select="*[1]"/>
                            <xsl:apply-templates select="*[position()>1]"/>
                        </datafield>
                    </xsl:for-each>
                </xsl:if>
                <!-- 040 - Cataloging Source (NR) -->
                <xsl:if test="//*[@tag='040']">
                    <xsl:for-each select="//*[@tag='040'][local-name(*[1])='subfield']">
                        <datafield tag="040" ind1=" " ind2=" ">
                            <xsl:apply-templates select="*[1]"/>
                            <xsl:apply-templates select="*[position()>1]"/>
                        </datafield>
                    </xsl:for-each>
                </xsl:if>

                <!-- 043 Geographic Area Code (R) -->
                <xsl:if test="//*[@tag='043']">
                    <xsl:for-each select="//*[@tag='043'][local-name(*[1])='subfield']">
                        <datafield tag="043" ind1=" " ind2=" ">
                            <xsl:apply-templates select="*[1]"/>
                            <xsl:apply-templates select="*[position()>1]"/>
                        </datafield>
                    </xsl:for-each>
                </xsl:if>
                <!-- 050 - Library of Congress Call Number (R) select first data from MARC second from MODS in seperate fields-->
                <xsl:choose>
                    <xsl:when test="//*[local-name()='classification'][@authority='lcc']">
                        <xsl:for-each select="//*[local-name()='classification'][@authority='lcc']">
                            <xsl:call-template name="datafield">
                                <xsl:with-param name="tag">050</xsl:with-param>
                                <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                                <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                                <xsl:with-param name="subfields">
                                    <xsl:call-template name="lccNumber"/> 
                                </xsl:with-param>
                            </xsl:call-template>
                        </xsl:for-each>
                    </xsl:when>
                    <!-- if 050 is empty add LCC from 090 subfield "a" Locally Assigned LC-type Call Number -->
                    <xsl:otherwise>
                        <xsl:if test="//*[@tag='050'][local-name(*[1])='subfield']">
                            <xsl:for-each select="//*[@tag='050'][local-name(*[1])='subfield']">
                                <xsl:call-template name="datafield">
                                    <xsl:with-param name="tag">050</xsl:with-param>
                                    <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                                    <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                                    <xsl:with-param name="subfields">
                                        <xsl:apply-templates select="*[1]"/>
                                        <xsl:apply-templates select="*[position()>1]"/>
                                    </xsl:with-param>
                                </xsl:call-template>
                            </xsl:for-each>
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- 051 - Library of Congress Copy, Issue, Offprint Statement (R) -->       
                <xsl:if test="//*[@tag='051']">
                    <xsl:for-each select="//*[@tag='051'][local-name(*[1])='subfield']">
                        <datafield tag="051" ind1=" " ind2=" ">
                            <xsl:apply-templates select="*[1]"/>
                            <xsl:apply-templates select="*[position()>1]"/>
                        </datafield>
                    </xsl:for-each>
                </xsl:if>
                <!-- 082 - Dewey Decimal Classification Number (R) -->
                <xsl:if test="//*[@tag='082']">
                    <xsl:for-each select="//*[@tag='082'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">082</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 090  Locally Assigned LC-type Call Number (R) https://www.oclc.org/bibformats/en/0xx/090.html  -->          
                <xsl:if test="//*[@tag='090']">
                    <xsl:for-each select="//*[@tag='090'][local-name(*[1])='subfield']">
                        <datafield tag="090" ind1=" " ind2=" ">
                            <xsl:apply-templates select="*[1]"/>
                            <xsl:apply-templates select="*[position()>1]"/>
                        </datafield>
                    </xsl:for-each>
                </xsl:if>        
                <!-- 092  Locally Assigned Dewey Call Number (R)-->            
                <xsl:if test="//*[@tag='092']">
                    <xsl:for-each select="//*[@tag='092'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">092</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 100 - Main Entry - Personal Name (NR) -->
                <xsl:if test="//*[@tag='100']">
                    <xsl:for-each select="//*[@tag='100'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">100</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 110 - Main Entry-Corporate Name (NR) -->
                <xsl:if test="//*[@tag='110']">
                    <xsl:for-each select="//*[@tag='110'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">110</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 111 - Main Entry-Meeting Name (NR) -->
                <xsl:if test="//*[@tag='111']">
                    <xsl:for-each select="//*[@tag='111'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">111</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"> </xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 130  Main Entry-Uniform Title (NR) -->
                <xsl:if test="//*[@tag='130']">
                    <xsl:for-each select="//*[@tag='130'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">130</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"> </xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>            
                <!-- 240 - Uniform Title (NR) -->
                <xsl:if test="//*[@tag='240']">
                    <xsl:for-each select="//*[@tag='240'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">240</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>            
                <!-- 245 - Title Statement (NR) -->
                <xsl:if test="//*[@tag='245']">
                    <xsl:for-each select="//*[@tag='245'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">245</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>           
                <!-- 246 - Varying Form of Title (R) -->
                <xsl:if test="//*[@tag='246']">
                    <xsl:for-each select="//*[@tag='246'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">246</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>            
                <!-- 247 - Former Title (R) -->
                <xsl:if test="//*[@tag='247']">
                    <xsl:for-each select="//*[@tag='247'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">247</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 250  Edition Statement (R) -->
                <xsl:if test="//*[@tag='250']">
                    <xsl:for-each select="//*[@tag='250'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">250</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>            
                <!-- 260 - Publication, Distribution, etc. (Imprint) (R)after k10plus mapping publication/publisher/distributor in 264 a=place b=name c=date -->
                <xsl:if test="//*[@tag='260']">
                    <xsl:for-each select="//*[@tag='260'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">264</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>                      
                <!-- 264 - Production, Publication, Distribution, Manufacture, and Copyright Notice (R) -->
                <xsl:if test="//*[@tag='264']">
                    <xsl:for-each select="//*[@tag='264'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">264</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>            
                <!-- 300 - Physical Description (R) -->
                <xsl:if test="//*[@tag='300']">
                    <xsl:for-each select="//*[@tag='300'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">300</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>            
                <!-- 300 MARC from mods data -->
                <xsl:if test="//*[local-name()='physicalDescription']/*[local-name()='extent'][@unit='duration']">
                    <datafield tag="300" ind1=" " ind2=" ">
                        <subfield code="a">
                            <xsl:value-of select="//*[local-name()='physicalDescription']/*[local-name()='extent'][@unit='duration']/text()"/>
                        </subfield>
                    </datafield>
                </xsl:if>            
                <!-- 310 - Current Publication Frequency (R) -->
                <xsl:if test="//*[@tag='310']">
                    <xsl:for-each select="//*[@tag='310'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">310</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>            
                <!-- 321 - Former Publication Frequency (R) -->
                <xsl:if test="//*[@tag='321']">
                    <xsl:for-each select="//*[@tag='321'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">321</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>            
                <!-- 336 - Content Type (R) -->
                <xsl:if test="//*[@tag='336']">
                    <xsl:for-each select="//*[@tag='336'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">336</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 337 - Media Type (R) -->
                <xsl:if test="//*[@tag='337']">
                    <xsl:for-each select="//*[@tag='337'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">337</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 338 - Carrier Type (R) -->
                <xsl:if test="//*[@tag='338']">
                    <xsl:for-each select="//*[@tag='338'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">338</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>            
                <!-- 340 - Physical Medium (R) -->
                <xsl:if test="//*[@tag='340']">
                    <xsl:for-each select="//*[@tag='340'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">340</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 362 - Dates of Publication and/or Sequential Designation (R) -->
                <xsl:if test="//*[@tag='362']">
                    <xsl:for-each select="//*[@tag='362'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">362</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>            
                <!-- 400 - Series Statement/Added Entry-Personal Name (R) -->
                <xsl:if test="//*[@tag='400']">
                    <xsl:for-each select="//*[@tag='400'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">400</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>            
                <!-- 410 - Series Statement/Added Entry-Corporate Name (R) -->
                <xsl:if test="//*[@tag='410']">
                    <xsl:for-each select="//*[@tag='410'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">410</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>            
                <!-- 440 - Series Statement/Added Entry-Title (R) -->
                <!-- 440 convert to field 490 Ind1"0" Ind2 " "-->
                <xsl:choose>
                    <xsl:when test="//*[@tag='440']">
                        <xsl:for-each select="//*[@tag='440'][local-name(*[1])='subfield']">
                            <xsl:call-template name="datafield">
                                <xsl:with-param name="tag">490</xsl:with-param>
                                <xsl:with-param name="ind1"><xsl:text>0</xsl:text></xsl:with-param>
                                <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                                <xsl:with-param name="subfields">
                                    <xsl:apply-templates select="*[1]"/>
                                    <xsl:apply-templates select="*[position()>1]"/>
                                </xsl:with-param>
                            </xsl:call-template>
                        </xsl:for-each>
                    </xsl:when> 
                    <xsl:otherwise>
                        <!-- 490 - Series Statement (R) -->
                        <xsl:if test="//*[@tag='490']">
                            <xsl:for-each select="//*[@tag='490'][local-name(*[1])='subfield']">
                                <xsl:call-template name="datafield">
                                    <xsl:with-param name="tag">490</xsl:with-param>
                                    <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                                    <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                                    <xsl:with-param name="subfields">
                                        <xsl:apply-templates select="*[1]"/>
                                        <xsl:apply-templates select="*[position()>1]"/>
                                    </xsl:with-param>
                                </xsl:call-template>
                            </xsl:for-each>
                        </xsl:if> 
                    </xsl:otherwise>
                </xsl:choose>
                      
                <!-- 500 - General Note (R) -->
                <xsl:if test="//*[@tag='500']">
                    <xsl:for-each select="//*[@tag='500'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">500</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>            
                <!-- 501 - With Note (R) -->
                <xsl:if test="//*[@tag='501']">
                    <xsl:for-each select="//*[@tag='501'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">501</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>            
                <!-- 502 - Dissertation Note (R) -->
                <xsl:if test="//*[@tag='502']">
                    <xsl:for-each select="//*[@tag='502'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">502</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 503 convert to 500 -->
                <xsl:if test="//*[@tag='503']">
                    <xsl:for-each select="//*[@tag='503'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">500</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 504 - Bibliography, Etc. Note (R) -->
                <xsl:if test="//*[@tag='504']">
                    <xsl:for-each select="//*[@tag='504'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">504</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 505 - Formatted Contents Note (R) -->
                <xsl:if test="//*[@tag='505']">
                    <xsl:for-each select="//*[@tag='505'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">505</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 506 - Restrictions on Access Note (R) -->
                <xsl:if test="//*[@tag='506']">
                    <xsl:for-each select="//*[@tag='506'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">506</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 507 - Scale Note for Visual Materials (NR) -->
                <xsl:if test="//*[@tag='507']">
                    <datafield tag="507" ind1=" " ind2=" ">
                        <xsl:for-each select="//*[@tag='507']/*[@code='a']">
                            <subfield code="a">
                                <xsl:value-of select="."/>
                            </subfield>
                        </xsl:for-each>
                        <xsl:for-each select="//*[@tag='507']/*[@code='b']">
                            <subfield code="b">
                                <xsl:value-of select="."/>
                            </subfield>
                        </xsl:for-each>
                        <xsl:for-each select="//*[@tag='507']/*[@code='6']">
                            <subfield code="6">
                                <xsl:value-of select="."/>
                            </subfield>
                        </xsl:for-each>
                        <xsl:for-each select="//*[@tag='507']/*[@code='8']">
                            <subfield code="8">
                                <xsl:value-of select="."/>
                            </subfield>
                        </xsl:for-each>
                    </datafield>   
                </xsl:if>
                <!-- 510 - Citation/References Note (R) -->
                <xsl:if test="//*[@tag='510']">
                    <xsl:for-each select="//*[@tag='510'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">510</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 515 - Numbering Peculiarities Note (R) -->
                <xsl:if test="//*[@tag='515']">
                    <xsl:for-each select="//*[@tag='515'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">515</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 518 - Date/Time and Place of an Event Note (R) -->
                <xsl:if test="//*[@tag='518']">
                    <xsl:for-each select="//*[@tag='518'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">518</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>          
                <!-- 520 - Summary, Etc. (R) -->
                <xsl:if test="//*[@tag='520']">
                    <xsl:for-each select="//*[@tag='520'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">520</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 521 - Target Audience Note (R) -->
                <xsl:if test="//*[@tag='521']">
                    <xsl:for-each select="//*[@tag='521'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">521</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 525 - Supplement Note (R) -->
                <xsl:if test="//*[@tag='525']">
                    <xsl:for-each select="//*[@tag='525'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">525</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 530 - Additional Physical Form Available Note (R) -->
                <xsl:if test="//*[@tag='530']">
                    <xsl:for-each select="//*[@tag='530'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">530</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 533 - Reproduction Note (R) -->
                <xsl:if test="//*[@tag='533']">
                    <xsl:for-each select="//*[@tag='533'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">533</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 540 - Terms Governing Use and Reproduction Note (R) -->
                <xsl:if test="//*[@tag='540']">
                    <xsl:for-each select="//*[@tag='540'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">540</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 550 - Issuing Body Note (R) -->
                <xsl:if test="//*[@tag='550']">
                    <xsl:for-each select="//*[@tag='550'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">550</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 580 - Linking Entry Complexity Note (R) -->
                <xsl:if test="//*[@tag='580']">
                    <xsl:for-each select="//*[@tag='580'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">580</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 588 - Source of Description, Etc. Note (R) -->
                <xsl:if test="//*[@tag='588']">
                    <xsl:for-each select="//*[@tag='588'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">588</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>  
                <!-- 600 - Subject Added Entry-Personal Name (R) -->
                <xsl:if test="//*[@tag='600']">
                    <xsl:for-each select="//*[@tag='600'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">600</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 610 - Subject Added Entry-Corporate Name (R) -->
                <xsl:if test="//*[@tag='610']">
                    <xsl:for-each select="//*[@tag='610'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">610</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 611 - Subject Added Entry-Meeting Name (R) -->
                <xsl:if test="//*[@tag='611']">
                    <xsl:for-each select="//*[@tag='611'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">611</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 630 - Subject Added Entry-Uniform Title (R) -->
                <xsl:if test="//*[@tag='630'] and not(mods:subject[local-name(*[1])='titleInfo'])">
                    <xsl:for-each select="//*[@tag='630'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">630</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 647 - Subject Added Entry-Named Event (R) -->
                <xsl:if test="//*[@tag='647']">
                    <xsl:for-each select="//*[@tag='647'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">647</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 648 - Subject Added Entry-Chronological Term (R) -->
                <xsl:if test="//*[@tag='648']">
                    <xsl:for-each select="//*[@tag='648'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">648</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 650 - Subject Added Entry-Topical Term (R) -->
                <!-- only if MODS doesn't have subject tags, then grab it from MARC 650  -->
                <xsl:if test="//*[@tag='650'] and not(mods:subject[local-name(*[1])='topic'])">
                    <xsl:for-each select="//*[@tag='650'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">650</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 651 - Subject Added Entry-Geographic Name (R) -->
                <xsl:if test="//*[@tag='651'] and not(mods:subject[local-name(*[1])='geographic'])">
                    <xsl:for-each select="//*[@tag='651'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">651</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 653 - Index Term-Uncontrolled (R) -->
                <xsl:if test="//*[@tag='653']">
                    <xsl:for-each select="//*[@tag='653'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">653</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 655 - Index Term-Genre/Form (R) -->
                <xsl:if test="//*[@tag='655']">
                    <xsl:for-each select="//*[@tag='655'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">655</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 690 - Local Subject Added Entry-Topical Term (R) -->
                <!-- 690 already converted in 650 -->
                <!-- <xsl:if test="//*[@tag='690']">
                    <xsl:for-each select="//*[@tag='690'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">690</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>-->
                <!-- 691 - Local Subject Added Entry-Geographic Name (R) -->
                <!-- <xsl:if test="//*[@tag='691']">
                    <xsl:for-each select="//*[@tag='691'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">691</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>-->
    
                <xsl:apply-templates/>
                
                <!-- 650 MARC from MODS data [besser als Lokales Schlagwort im Exemplardaten?]-->
                <xsl:if test="//*[local-name()='physicalDescription']/*[local-name()='form'][@authority='local']">
                    <datafield tag="650" ind1=" " ind2="4">
                        <subfield code="a">
                            <xsl:value-of select="concat('|f|', //*[local-name()='physicalDescription']/*[local-name()='form'][@authority='local']/text())"/>
                        </subfield>
                    </datafield>
                </xsl:if>
                
                <!-- 698 - Local Subject Added Entry-Meeting Name (R) -->
                <xsl:if test="//*[@tag='698']">
                    <xsl:for-each select="//*[@tag='698'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">698</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 699 - Local Subject Added Entry-Uniform Title (R) -->
                <xsl:if test="//*[@tag='699']">
                    <xsl:for-each select="//*[@tag='699'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">699</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 700 - Added Entry-Personal Name (R) -->
                <xsl:if test="//*[@tag='700']">
                    <xsl:for-each select="//*[@tag='700'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">700</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 710 - Added Entry-Corporate Name (R) -->
                <xsl:if test="//*[@tag='710']">
                    <xsl:for-each select="//*[@tag='710'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">710</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 711 - Added Entry-Meeting Name (R) -->
                <xsl:if test="//*[@tag='711']">
                    <xsl:for-each select="//*[@tag='711'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">711</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 720 - Added Entry-Uncontrolled Name (R) -->
                <xsl:if test="//*[@tag='720']">
                    <xsl:for-each select="//*[@tag='720'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">720</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 730 - Added Entry-Uniform Title (R) -->
                <xsl:if test="//*[@tag='730']">
                    <xsl:for-each select="//*[@tag='730'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">730</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 773 - Host Item Entry (R) -->
                <xsl:if test="//*[@tag='773']">
                    <xsl:for-each select="//*[@tag='773'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">773</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 775 - Other Edition Entry (R) -->
                <xsl:if test="//*[@tag='775']">
                    <xsl:for-each select="//*[@tag='775'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">775</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 776 - Additional Physical Form Entry (R) -->
                <xsl:if test="//*[@tag='776']">
                    <xsl:for-each select="//*[@tag='776'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">776</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 780 - Preceding Entry (R) -->
                <xsl:if test="//*[@tag='780']">
                    <xsl:for-each select="//*[@tag='780'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">780</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 785 - Succeeding Entry (R) -->
                <xsl:if test="//*[@tag='785']">
                    <xsl:for-each select="//*[@tag='785'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">785</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 800 - Series Added Entry-Personal Name (R) -->
                <xsl:if test="//*[@tag='800']">
                    <xsl:for-each select="//*[@tag='800'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">800</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 810 - Series Added Entry Corporate Name (R)  -->
                <xsl:if test="//*[@tag='810']">
                    <xsl:for-each select="//*[@tag='810'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">810</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 811 - Series Added Entry-Meeting Name (R)  -->
                <xsl:if test="//*[@tag='811']">
                    <xsl:for-each select="//*[@tag='811'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">811</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 830 - Series Added Entry-Uniform Title (R)  -->
                <xsl:if test="//*[@tag='830']">
                    <xsl:for-each select="//*[@tag='830'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">830</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 852 - Location (R) -->
                <!-- 852 will override/add by "DE-Tue135" -->
                <xsl:choose>
                    <xsl:when test="//*[@tag='852']">
                        <xsl:for-each select="//*[@tag='852'][local-name(*[1])='subfield']">
                            <xsl:call-template name="datafield">
                                <xsl:with-param name="tag">852</xsl:with-param>
                                <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                                <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                                <xsl:with-param name="subfields">
                                    <subfield code="a">
                                        <xsl:text>DE-Tue135</xsl:text>
                                    </subfield>
                                </xsl:with-param>
                            </xsl:call-template>
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:otherwise>
                        <datafield tag="852" ind1=" " ind2=" ">
                            <subfield code="a">DE-Tue135</subfield>
                        </datafield>
                    </xsl:otherwise>
                </xsl:choose>

                <!-- 856 - Electronic Location and Access (R) -->
                <xsl:if test="//*[@tag='856']">
                    <xsl:for-each select="//*[@tag='856'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">856</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 856 MARC from mods data without template-->
                <xsl:if test="//*[local-name()='url']">
                    <datafield tag="856" ind1="4" ind2="0">
                        <xsl:for-each select="//*[local-name()='url']">
                            <subfield code="u">
                                <xsl:value-of select="."/>
                            </subfield>
                        </xsl:for-each>
                        <subfield code="z">LF</subfield>
                    </datafield>
                </xsl:if>
                <!-- 866 - Textual Holdings - Basic Bibliographic Unit (R) -->
                <xsl:if test="//*[@tag='866']">
                    <xsl:for-each select="//*[@tag='866'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">866</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 866 MARC from mods data [Grobthemen "Subject" als Sammlungskonzept in MARC 866|x ] -->
                <!--<xsl:if test="//*[local-name()='topic']">
                    <datafield tag="866" ind1=" " ind2=" ">
                        <subfield code="x">
                            <xsl:value-of select="concat('SPQUE#Theological Commons Princeton#SPSYS#', //*[local-name()='topic']/text())"/>
                        </subfield>
                    </datafield>
                </xsl:if>-->

                <!-- add collections tags for navigation 866  -->
                <xsl:choose>
                    <!-- Albert Andrew Fulton Manuscript Collection -->
                    <xsl:when test="matches(mods:note, '^the\s?albert\s?andrew', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Albert Andrew Fulton Manuscript Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Ashbel Green Simonton Manuscript Collection -->
                    <xsl:when test="matches(mods:note, '^the\s?ashbel\s?green\s?simonton\s?manuscript\s?collection', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Ashbel Green Simonton Manuscript Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Academy of Homiletics -->
                    <xsl:when test="matches(mods:note, 'academy\s?of\s?homiletics', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Academy of Homiletics</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Academy of Homiletics -->
                    <xsl:when test="matches(mods:note, 'academy\s?of\s?homiletics', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Academy of Homiletics</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- The Belle Sparr Luckett Manuscript Collection -->
                    <xsl:when test="matches(mods:note, '^the\s?belle\s?sparr\s?luckett\s?manuscript\s?collection', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Benson collection of hymnals and hymnology</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Benson collection of hymnals and hymnology -->
                    <xsl:when test="matches(mods:note, '^benson\s?collection\s?of\s?hymnals', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Benson collection of hymnals and hymnology</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Beth Mardutho: The Syriac Institute -->
                    <xsl:when test="matches(//*[local-name()='collection_set'], '^bethmardutho', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Beth Mardutho: The Syriac Institute</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Caleb Cook Baldwin Manuscript Collection -->
                    <xsl:when test="matches(mods:note, '^caleb\s?cook\s?baldwin\s?manuscript', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Caleb Cook Baldwin Manuscript Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- David and Jane Wales Trumbull Manuscript Collection -->
                    <xsl:when test="matches(mods:note, '^david\s?and\s?jane\s?wales\s?trumbull', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#David and Jane Wales Trumbull Manuscript Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>                    
                    <!-- Earl palmer Collection all files are missing in ptsem_xx.zip ToDo:ask pts  -->
                    
                    <!-- Edward Warren Manuscript Collection -->
                    <xsl:when test="matches(mods:note, '^edward\s?warren\s?manuscript\s?collection', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Edward Warren Manuscript Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- The George H. Bowen Manuscript Collection -->
                    <xsl:when test="matches(mods:note, '^the\s?George\s?h\.?\s?bowen\s?manuscript', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#The George H. Bowen Manuscript Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- The Harry A. Rhodes Manuscript Collection -->
                    <xsl:when test="matches(mods:note, '^the\s?Harry\s?a\.?\s?rhodes\s?manuscript', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#The Harry A. Rhodes Manuscript Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- The James Watt Manuscript Collection -->
                    <xsl:when test="matches(mods:note, '^the\s?James\s?Watt\s?Manuscript\s?Collection', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#The James Watt Manuscript Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- John A. Mackay collection -->
                    <xsl:when test="matches(mods:note, '^John\s?A\.\s?Mackay\s?Collection', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#John A. Mackay collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Langley Kitching South Africa/Madagascar Collection -->
                    <xsl:when test="matches(mods:note, '^Langley\s?Kitching\s?South\s?Africa', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Langley Kitching South Africa/Madagascar Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Latin America Collection selection criteria is still unknown maybe <namePart>Henry Luce Foundation</namePart>-->
                    
                    <!-- Levi Janvier Manuscript Collection -->
                    <xsl:when test="matches(mods:note, '^Levi\s?Janvier\s?Manuscript\s?Collection', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Levi Janvier Manuscript Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Michael S. Culbertson Manuscript Collection -->
                    <xsl:when test="matches(mods:note, '^Michael\s?S\.\s?Culbertson\s?Manuscript', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Michael S. Culbertson Manuscript Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Missio Seminary Collection -->
                    <xsl:when test="matches(mods:name[@type='corporate']/mods:namePart, '^Missio\s?Seminary', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Missio Seminary Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Moffett Korea Collection -->
                    <xsl:when test="matches(mods:note, '^moffett\s?korea\s?collection', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Moffett Korea Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- MRL Pamplhlets selection criteria not defined ToDo:MAYBE with <namePart>-->
                    <!-- Payne Seminary/AME Archive ToDo:Check if <namePart> -->
                    <xsl:when test="matches(mods:name[@type='corporate']/mods:namePart, '^African\s?Methodist\s?Episcopal\s?Church', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Payne Seminary/AME Archive</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Payne Seminary/AME Archive ToDo:Check if <namePart> -->
                    <xsl:when test="matches(mods:name[@type='corporate']/mods:namePart, '^African\s?Methodist\s?Episcopal\s?Church', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Payne Seminary/AME Archive</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- PTS Journals ToDo:criteria unkown -->
                    <!-- PTS Media Archive ToDo:criteria unkown -->
                    <!-- Robert Elliott Speer Manuscript Collection -->
                    <xsl:when test="matches(mods:note, '^Robert\s?Elliott\s?Speer\s?Manuscript', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Robert Elliott Speer Manuscript Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Robert Hamill Nassau Manuscript Collection -->
                    <xsl:when test="matches(mods:note, '^Robert\s?Hamill\s?Nassau\s?Manuscript', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Robert Hamill Nassau Manuscript Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- The Scott Family  Collection -->
                    <xsl:when test="matches(mods:note, '^the\s?Scott\s?Family', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#The Scott Family Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Seminario Evangélico P.R. all files are missing in ptsem_xx.zip ToDo:ask pts-->
                    <!-- Sheldon Jackson Collection ToDo:criteria unkown -->
                    <!-- Thomas F. Torrance Collection -->
                    <xsl:when test="matches(mods:note, '^Thomas\s?F\.\s?Torrance\sCollection?', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Thomas F. Torrance Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Tanis Postcards Collection ToDo:mods:name[@type='personal'] "James R. Tanis" AND mods:physicalDescription/mods:form[@authority='local'] = "Postcard"-->
                    <!-- Weld Missionary Papers -->
                    <xsl:when test="matches(mods:note, '^William\s?E\.\s?and\s?Margaret\s?E\.\s?Weld', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Weld Missionary Papers</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Youth Lectures ToDo:criteria unkown-->
                    <xsl:otherwise>     
                    </xsl:otherwise>
                </xsl:choose>
                
                <!-- add collections tags for navigations if collection info is stored only in 730  e.g. https://commons.ptsem.edu/id/150thanniversary00cong -->
                <xsl:choose>
                    <!-- Albert Andrew Fulton Manuscript Collection -->
                    <xsl:when test="matches(//*[@tag='730']/*[@code='a']/text(), '^the\s?albert\s?andrew', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Albert Andrew Fulton Manuscript Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Ashbel Green Simonton Manuscript Collection -->
                    <xsl:when test="matches(//*[@tag='730']/*[@code='a']/text(), '^the\s?ashbel\s?green\s?simonton\s?manuscript\s?collection', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Ashbel Green Simonton Manuscript Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- The Belle Sparr Luckett Manuscript Collection -->
                    <xsl:when test="matches(//*[@tag='730']/*[@code='a']/text(), '^the\s?belle\s?sparr\s?luckett\s?manuscript\s?collection', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Ashbel Green Simonton Manuscript Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Benson collection of hymnals and hymnology -->
                    <xsl:when test="matches(//*[@tag='730']/*[@code='a']/text(), '^benson\s?collection\s?of\s?hymnals', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Benson collection of hymnals and hymnology</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- David and Jane Wales Trumbull Manuscript Collection -->
                    <xsl:when test="matches(//*[@tag='730']/*[@code='a']/text(), '^david\s?and\s?jane\s?wales\s?trumbull', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#David and Jane Wales Trumbull Manuscript Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>                    
                    <!-- Earl palmer Collection all files are missing in ptsem_xx.zip  -->
                    
                    <!-- Edward Warren Manuscript Collection -->
                    <xsl:when test="matches(//*[@tag='730']/*[@code='a']/text(), '^edward\s?warren\s?manuscript\s?collection', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Edward Warren Manuscript Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- The George H. Bowen Manuscript Collection -->
                    <xsl:when test="matches(//*[@tag='730']/*[@code='a']/text(), '^the\s?George\s?h\.?\s?bowen\s?manuscript', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#The George H. Bowen Manuscript Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- The Harry A. Rhodes Manuscript Collection -->
                    <xsl:when test="matches(//*[@tag='730']/*[@code='a']/text(), '^the\s?Harry\s?a\.?\s?rhodes\s?manuscript', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#The Harry A. Rhodes Manuscript Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- The James Watt Manuscript Collection -->
                    <xsl:when test="matches(//*[@tag='730']/*[@code='a']/text(), '^the\s?James\s?Watt\s?Manuscript\s?Collection', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#The James Watt Manuscript Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- John A. Mackay collection -->
                    <xsl:when test="matches(//*[@tag='730']/*[@code='a']/text(), '^John\s?A\.\s?Mackay\s?Collection', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#John A. Mackay collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Langley Kitching South Africa/Madagascar Collection -->
                    <xsl:when test="matches(//*[@tag='730']/*[@code='a']/text(), '^Langley\s?Kitching\s?South\s?Africa', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Langley Kitching South Africa/Madagascar Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Latin America Collection selection criteria is still unknown maybe <namePart>Henry Luce Foundation</namePart>-->
                    
                    <!-- Levi Janvier Manuscript Collection -->
                    <xsl:when test="matches(//*[@tag='730']/*[@code='a']/text(), '^Levi\s?Janvier\s?Manuscript\s?Collection', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Levi Janvier Manuscript Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Michael S. Culbertson Manuscript Collection -->
                    <xsl:when test="matches(m//*[@tag='730']/*[@code='a']/text(), '^Michael\s?S\.\s?Culbertson\s?Manuscript', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Michael S. Culbertson Manuscript Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Missio Seminary Collection -->
                    <xsl:when test="matches(//*[@tag='730']/*[@code='a']/text(), '^Missio\s?Seminary', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Missio Seminary Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Moffett Korea Collection -->
                    <xsl:when test="matches(//*[@tag='730']/*[@code='a']/text(), '^moffett\s?korea\s?collection', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Moffett Korea Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- MRL Pamphlets selection criteria not defined ToDo:MAYBE with <namePart>-->
                    <!-- Payne Seminary/AME Archive ToDo:Check if <namePart> -->
                    <xsl:when test="matches(//*[@tag='730']/*[@code='a']/text(), '^African\s?Methodist\s?Episcopal\s?Church', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Payne Seminary/AME Archive</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Payne Seminary/AME Archive ToDo:Check if <namePart> -->
                    <xsl:when test="matches(//*[@tag='730']/*[@code='a']/text(), '^African\s?Methodist\s?Episcopal\s?Church', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Payne Seminary/AME Archive</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- PTS Journals ToDo:criteria unkown -->
                    <!-- PTS Media Archive ToDo:criteria unkown -->
                    <!-- Robert Elliott Speer Manuscript Collection -->
                    <xsl:when test="matches(//*[@tag='730']/*[@code='a']/text(), '^Robert\s?Elliott\s?Speer\s?Manuscript', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Robert Elliott Speer Manuscript Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Robert Hamill Nassau Manuscript Collection -->
                    <xsl:when test="matches(//*[@tag='730']/*[@code='a']/text(), '^Robert\s?Hamill\s?Nassau\s?Manuscript', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Robert Hamill Nassau Manuscript Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- The Scott Family  Collection -->
                    <xsl:when test="matches(//*[@tag='730']/*[@code='a']/text(), '^the\s?Scott\s?Family', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#The Scott Family Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Seminario Evangélico P.R. all files are missing in ptsem_xx.zip ToDo:ask pts-->
                    <!-- Sheldon Jackson Collection ToDo:criteria unkown -->
                    <!-- Thomas F. Torrance Collection -->
                    <xsl:when test="matches(//*[@tag='730']/*[@code='a']/text(), '^Thomas\s?F\.\s?Torrance\sCollection?', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Thomas F. Torrance Collection</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Tanis Postcards Collection ToDo:mods:name[@type='personal'] "James R. Tanis" AND mods:physicalDescription/mods:form[@authority='local'] = "Postcard"-->
                    <!-- Weld Missionary Papers -->
                    <xsl:when test="matches(//*[@tag='730']/*[@code='a']/text(), '^William\s?E\.\s?and\s?Margaret\s?E\.\s?Weld', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Weld Missionary Papers</xsl:text>                          
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Youth Lectures ToDo:criteria unkown--> 
                    <xsl:otherwise>     
                    </xsl:otherwise>
                </xsl:choose>
                
                <!-- 876 - Item Information - Basic Bibliographic Unit (R)  -->
                <xsl:if test="//*[@tag='876']">
                    <xsl:for-each select="//*[@tag='876'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">876</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                <!-- 880 - Alternate Graphic Representation (R) -->
                <xsl:if test="//*[@tag='880']">
                    <xsl:for-each select="//*[@tag='880'][local-name(*[1])='subfield']">
                        <xsl:call-template name="datafield">
                            <xsl:with-param name="tag">880</xsl:with-param>
                            <xsl:with-param name="ind1"><xsl:call-template name="firstIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="ind2"><xsl:call-template name="secondIndFromMarc"/></xsl:with-param>
                            <xsl:with-param name="subfields">
                                <xsl:apply-templates select="*[1]"/>
                                <xsl:apply-templates select="*[position()>1]"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>

                <!-- Match&Merge unterdrücken -->
                <xsl:choose>
                    <xsl:when test="//*[@tag='912']">
                        <datafield tag="912" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:value-of select="//*[@tag='912']/*[@code='a']/text()"/>
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <xsl:otherwise>
                        <datafield tag="912" ind1=" " ind2=" ">
                            <subfield code="a">NOMM</subfield>
                        </datafield>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="//*[@tag='913']">
                    <datafield tag="913" ind1="0" ind2="0">
                        <subfield code="a">
                            <xsl:value-of select="//*[@tag='913']/*[@code='a']/text()"/>
                        </subfield>
                    </datafield>
                </xsl:if>
                <!-- Abrufzeichen fuer Princeton Theological Commons -->
                <xsl:choose>
                    <xsl:when test="//*[@tag='935']">
                        <datafield tag="935" ind1=" " ind2=" ">
                            <subfield code="a">prtc</subfield>
                            <subfield code="2">LOK</subfield>
                        </datafield>
                    </xsl:when>
                    <xsl:otherwise>
                        <datafield tag="935" ind1=" " ind2=" ">
                            <subfield code="a">prtc</subfield>
                            <subfield code="2">LOK</subfield>
                        </datafield>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- 9xx internal field  maybe date of cataloging-->
                <xsl:if test="//*[@tag='948']">
                    <datafield tag="948" ind1=" " ind2=" ">
                        <xsl:for-each select="//*[@tag='948']/*[@code='a']">
                            <subfield code="a">
                                <xsl:value-of select="."/>
                            </subfield>
                        </xsl:for-each>
                        <xsl:for-each select="//*[@tag='948']/*[@code='b']">
                            <subfield code="b">
                                <xsl:value-of select="."/>
                            </subfield>
                        </xsl:for-each>
                    </datafield>
                </xsl:if>
                
                <!-- 9xx internal field -->            
    
                <!-- 9xx internal field  maybe date of cataloging-->
                <!--<xsl:if test="//*[@tag='988']">
                    <datafield tag="988" ind1=" " ind2=" ">
                        <xsl:for-each select="//*[@tag='988']/*[@code='a']">
                            <subfield code="a">
                                <xsl:value-of select="."/>
                            </subfield>
                        </xsl:for-each>
                        <xsl:for-each select="//*[@tag='988']/*[@code='c']">
                            <subfield code="c">
                                <xsl:value-of select="."/>
                            </subfield>
                        </xsl:for-each>
                    </datafield>
                </xsl:if>-->
            </record>     
        </collection>
    </xsl:template>

<!-- templates with subfield matches-->
    <xsl:template match="mods:datafield">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='a']">
        <subfield code="a">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='b']">
        <subfield code="b">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='c']">
        <subfield code="c">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='d']">
        <subfield code="d">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='e']">
        <subfield code="e">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='f']">
        <subfield code="f">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='g']">
        <subfield code="g">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='h']">
        <subfield code="h">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='i']">
        <subfield code="i">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='j']">
        <subfield code="j">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='k']">
        <subfield code="k">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='l']">
        <subfield code="l">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='m']">
        <subfield code="m">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='n']">
        <subfield code="n">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='o']">
        <subfield code="o">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='p']">
        <subfield code="p">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='q']">
        <subfield code="q">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='r']">
        <subfield code="r">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='s']">
        <subfield code="s">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='t']">
        <subfield code="t">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='u']">
        <subfield code="u">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='v']">
        <subfield code="v">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='w']">
        <subfield code="w">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='x']">
        <subfield code="x">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='y']">
        <subfield code="y">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='z']">
        <subfield code="z">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='0']">
        <subfield code="0">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='1']">
        <subfield code="1">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='2']">
        <subfield code="2">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='3']">
        <subfield code="3">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='4']">
        <subfield code="4">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='5']">
        <subfield code="5">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='6']">
        <subfield code="6">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='7']">
        <subfield code="7">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='8']">
        <subfield code="8">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag]/*[@code='9']">
        <subfield code="9">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    
    
    <!-- split LCC in Class Number subfield a and Item Number subfield b -->
    <xsl:template name="lccNumber">
        <xsl:for-each select="//*[local-name()='classification'][@authority='lcc'][@authority='lcc'][substring-after(//*[local-name()='classification'][@authority='lcc'], ' ')]">
            <subfield code="a">
                <xsl:value-of select="substring-before(//*[local-name()='classification'][@authority='lcc'], ' ')"/>
            </subfield>
        </xsl:for-each>
        <xsl:choose>
            <xsl:when test="//*[local-name()='classification'][@authority='lcc'][substring-after(//*[local-name()='classification'][@authority='lcc'], ' .')]">
                <xsl:for-each select="//*[local-name()='classification'][@authority='lcc'][substring-after(//*[local-name()='classification'][@authority='lcc'], ' .')]">
                    <subfield code="b">
                        <xsl:value-of select="substring-after(//*[local-name()='classification'][@authority='lcc'], ' .')"/>
                    </subfield>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="//*[@tag='050'][local-name(*[1])='subfield']/*[@code='b'][substring-after(//*[local-name()='classification'][@authority='lcc'], ' ')]">
                    <subfield code="b">
                        <xsl:value-of select="//*[@tag='050'][local-name(*[1])='subfield']/*[@code='b']"/>
                    </subfield>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- data clean for specific subfields -->
    <xsl:template match="//*[@tag='090']/*[@code='a']">
        <subfield code="a">
            <xsl:choose>
                <xsl:when test="//*[@tag='090']/*[@code='a']/text()[substring(., string-length()) ='.']">
                    <xsl:value-of select="//*[@tag='090']/*[@code='a']/text()[substring(., string-length() = 0)]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </subfield>
    </xsl:template>
       
    <xsl:template match="//*[@tag='092']/*[@code='a']">
        <subfield code="a">
            <xsl:choose>
                <xsl:when test="//*[@tag='092']/*[@code='a']/text()[substring(., string-length()) ='.']">
                    <xsl:value-of select="//*[@tag='092']/*[@code='a']/text()[substring(., string-length() = 0)]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </subfield>
    </xsl:template>
        
    <xsl:template match="//*[@tag='096']/*[@code='a']">
        <subfield code="a">
            <xsl:choose>
                <xsl:when test="//*[@tag='096']/*[@code='a']/text()[substring(., string-length()) ='.']">
                    <xsl:value-of select="//*[@tag='096']/*[@code='a']/text()[substring(., string-length() = 0)]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </subfield>
    </xsl:template>
       
    <xsl:template match="//*[@tag='098']/*[@code='a']">
        <subfield code="a">
            <xsl:choose>
                <xsl:when test="//*[@tag='098']/*[@code='a']/text()[substring(., string-length()) ='.']">
                    <xsl:value-of select="//*[@tag='098']/*[@code='a']/text()[substring(., string-length() = 0)]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </subfield>
    </xsl:template>
      
    <xsl:template match="//*[@tag='099']/*[@code='a']">
        <subfield code="a">
            <xsl:choose>
                <xsl:when test="//*[@tag='099']/*[@code='a']/text()[substring(., string-length()) ='.']">
                    <xsl:value-of select="//*[@tag='099']/*[@code='a']/text()[substring(., string-length() = 0)]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </subfield>
    </xsl:template>
       
    <xsl:template match="//*[@tag='100']/*[@code='a']">
        <subfield code="a">
            <xsl:choose>
                <xsl:when test="text()[substring(., string-length()) =',']">
                    <xsl:value-of select="substring(., 1, string-length() - 1)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag='100']/*[@code='b']">
        <subfield code="b">
            <xsl:choose>
                <xsl:when test="text()[substring(., string-length()) =',']">
                    <xsl:value-of select="substring(., 1, string-length() - 1)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag='100']/*[@code='c']">
        <subfield code="c">
            <xsl:choose>
                <xsl:when test="text()[substring(., string-length()) =',']">
                    <xsl:value-of select="substring(., 1, string-length() - 1)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </subfield>
    </xsl:template>
    <!-- ToDo: date without or with dot? e.g.: <subfield code="d">1862-1936.</subfield>-->
    <xsl:template match="//*[@tag='100']/*[@code='d']">
        <subfield code="d">
            <xsl:choose>
                <xsl:when test="text()[substring(., string-length()) ='.']">
                    <xsl:value-of select="substring(., 1, string-length() - 1)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </subfield>
    </xsl:template>
      
    <xsl:template match="//*[@tag='110']/*[@code='a']">
        <subfield code="a">
            <xsl:choose>
                <xsl:when test="text()[substring(., string-length()) ='.']">
                    <xsl:value-of select="substring(., 1, string-length() - 1)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag='110']/*[@code='b']">
        <subfield code="b">
            <xsl:choose>
                <xsl:when test="text()[substring(., string-length()) ='.']">
                    <xsl:value-of select="substring(., 1, string-length() - 1)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag='110']/*[@code='c']">
        <subfield code="c">
            <xsl:choose>
                <xsl:when test="text()[substring(., string-length()) ='.']">
                    <xsl:value-of select="substring(., 1, string-length() - 1)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag='110']/*[@code='d']">
        <subfield code="d">
            <xsl:choose>
                <xsl:when test="text()[substring(., string-length()) ='.']">
                    <xsl:value-of select="substring(., 1, string-length() - 1)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </subfield>
    </xsl:template>
        
    <xsl:template match="//*[@tag='111']/*[@code='a']">
        <subfield code="a">
            <xsl:choose>
                <xsl:when test="text()[substring(., string-length()) ='.']">
                    <xsl:value-of select="substring(., 1, string-length() - 1)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag='111']/*[@code='b']">
        <subfield code="b">
            <xsl:choose>
                <xsl:when test="text()[substring(., string-length()) ='.']">
                    <xsl:value-of select="substring(., 1, string-length() - 1)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag='111']/*[@code='c']">
        <subfield code="c">
            <xsl:choose>
                <xsl:when test="text()[substring(., string-length()) ='.']">
                    <xsl:value-of select="substring(., 1, string-length() - 1)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </subfield>
    </xsl:template>
    <xsl:template match="//*[@tag='111']/*[@code='d']">
        <subfield code="d">
            <xsl:choose>
                <xsl:when test="text()[substring(., string-length()) ='.']">
                    <xsl:value-of select="substring(., 1, string-length() - 1)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </subfield>
    </xsl:template>
    
    <xsl:template match="//*[@tag='600']/*[@code='a']">
        <subfield code="a">
            <xsl:choose>
                <xsl:when test="text()[substring(., string-length()) =',']">
                    <xsl:value-of select="substring(., 1, string-length() - 1)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </subfield>
    </xsl:template>
    <!-- indicators mapping template -->
    <xsl:template name="authorityInd">
        <xsl:choose>
            <xsl:when test="@authority='lcsh'">0</xsl:when>
            <xsl:when test="@authority='lcshac'">1</xsl:when>
            <xsl:when test="@authority='mesh'">2</xsl:when>
            <xsl:when test="@authority='csh'">3</xsl:when>
            <xsl:when test="@authority='nal'">5</xsl:when>
            <xsl:when test="@authority='rvm'">6</xsl:when>
            <xsl:when test="@authority">7</xsl:when>
            <xsl:otherwise><xsl:text> </xsl:text></xsl:otherwise><!-- v3 blank ind2 fix-->
        </xsl:choose>
    </xsl:template> 
    <xsl:template name="firstIndFromMarc">
        <xsl:value-of select="@ind1"/>
    </xsl:template>
    <xsl:template name="secondIndFromMarc">
        <xsl:value-of select="@ind2"/>
    </xsl:template>
    <!-- second indicator is undefined=# but some of MARC data has "0" e.g. "theoryofmissions00ande_0" -->
    <xsl:template name="MainEntryPersonalName">
        <xsl:choose>
            <xsl:when test="//*[@tag='100'][local-name(*[1])='subfield'][@ind2='0']"><xsl:text> </xsl:text></xsl:when>
            <xsl:when test="//*[@tag='100'][local-name(*[1])='subfield'][@ind2='1']"><xsl:text> </xsl:text></xsl:when>
            <xsl:when test="//*[@tag='100'][local-name(*[1])='subfield'][@ind2='3']"><xsl:text> </xsl:text></xsl:when>
            <xsl:otherwise><xsl:text> </xsl:text></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- from here on rules for MODS -->
    <xsl:template name="titleInfo">
        <xsl:for-each select="mods:title">
            <subfield code="a">
                <xsl:value-of select="../mods:nonSort"/><xsl:value-of select="."/>
            </subfield>
        </xsl:for-each>
        <!-- 1/04 fix -->
        <xsl:for-each select="mods:subTitle">
            <subfield code="b">
                <xsl:value-of select="."/>
            </subfield>
        </xsl:for-each>
        <xsl:for-each select="mods:partNumber">
            <subfield code="n">
                <xsl:value-of select="."/>
            </subfield>
        </xsl:for-each>
        <xsl:for-each select="mods:partName">
            <subfield code="p">
                <xsl:value-of select="."/>
            </subfield>
        </xsl:for-each>
    </xsl:template>
    <!-- note about collection -->
    <xsl:template match="mods:note[not(@type='statement of responsibility')]">
        <xsl:call-template name="datafield">
            <xsl:with-param name="tag">
                <xsl:choose>
                    <xsl:when test="@type='performers'">511</xsl:when>
                    <xsl:when test="@type='venue'">518</xsl:when>
                    <xsl:otherwise>500</xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>
            <xsl:with-param name="subfields">
                <subfield code='a'>
                    <xsl:value-of select="."/>
                </subfield>
                <!-- 1/04 fix: 856$u instead -->
                <!--<xsl:for-each select="@xlink:href">
					<marc:subfield code='u'>
						<xsl:value-of select="."/>
					</marc:subfield>
				</xsl:for-each>-->
            </xsl:with-param>
        </xsl:call-template>
        <xsl:for-each select="@xlink:href">
            <xsl:call-template name="datafield">
                <xsl:with-param name="tag">856</xsl:with-param>
                <xsl:with-param name="subfields">
                    <subfield code='u'>
                        <xsl:value-of select="."/>
                    </subfield>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="mods:subject">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="mods:subject[local-name(*[1])='name']">
        <xsl:for-each select="*[1]">
            <xsl:choose>
                <!-- only if MARC doesn't have subject tags, then grab it from MODS -->
                <xsl:when test="@type='personal' and not(//*[@tag='600'])">
                    <xsl:call-template name="datafield">
                        <xsl:with-param name="tag">600</xsl:with-param>
                        <xsl:with-param name="ind1">1</xsl:with-param>
                        <xsl:with-param name="ind2"><xsl:call-template name="authorityInd"/></xsl:with-param>
                        <xsl:with-param name="subfields">
                            <subfield code="a">
                                <!-- 2.02 -->
                                <xsl:for-each select="mods:namePart[not(@type = 'termsOfAddress') and not(@type='date')]">
                                    <xsl:choose>
                                        <xsl:when test="@type='family' and following-sibling::mods:namePart[@type='given']">
                                            <xsl:value-of select="concat(.,', ')"/>
                                        </xsl:when>
                                        <xsl:otherwise><xsl:value-of select="."/><xsl:if test="following-sibling::*"><xsl:text> </xsl:text></xsl:if></xsl:otherwise>
                                    </xsl:choose>
                                </xsl:for-each>
                            </subfield>
                            <!-- v3 termsofAddress -->
                            <xsl:for-each select="mods:namePart[@type='termsOfAddress']">
                                <subfield code="c">
                                    <xsl:value-of select="."/>
                                </subfield>
                            </xsl:for-each>
                            <xsl:for-each select="mods:namePart[@type='date']">
                                <!-- v3 namepart/date was $a; fixed to $d -->
                                <subfield code="d">
                                    <xsl:value-of select="."/>
                                </subfield>
                            </xsl:for-each>
                            <!-- v3 role -->
                            <xsl:for-each select="mods:role/mods:roleTerm[@type='text']">
                                <subfield code="e">
                                    <xsl:value-of select="."/>
                                </subfield>
                            </xsl:for-each>
                            <xsl:for-each select="mods:affiliation">
                                <subfield code="u">
                                    <xsl:value-of select="."/>
                                </subfield>
                            </xsl:for-each>
                            <xsl:apply-templates select="*[position()>1]"/>
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="@type='corporate' and not(//*[@tag='610'])">
                    <xsl:call-template name="datafield">
                        <xsl:with-param name="tag">610</xsl:with-param>
                        <xsl:with-param name="ind1">2</xsl:with-param>
                        <xsl:with-param name="ind2"><xsl:call-template name="authorityInd"/></xsl:with-param>
                        <xsl:with-param name="subfields">
                            <subfield code="a">
                                <xsl:value-of select="mods:namePart[1]"/>
                            </subfield>
                            <xsl:for-each select="mods:namePart[position()>1]">
                                <subfield code="a">
                                    <xsl:value-of select="."/>
                                </subfield>
                            </xsl:for-each>
                            <!-- v3 role -->
                            <xsl:for-each select="mods:role/mods:roleTerm[@type='text']">
                                <subfield code="e">
                                    <xsl:value-of select="."/>
                                </subfield>
                            </xsl:for-each>
                            <!--<xsl:apply-templates select="*[position()>1]"/>-->
                            <xsl:apply-templates select="ancestor-or-self::mods:subject/*[position()>1]"/>  
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="@type='conference' and not(//*[@tag='611'])">
                    <xsl:call-template name="datafield">
                        <xsl:with-param name="tag">611</xsl:with-param>
                        <xsl:with-param name="ind1">2</xsl:with-param>
                        <xsl:with-param name="ind2"><xsl:call-template name="authorityInd"/></xsl:with-param>
                        <xsl:with-param name="subfields">
                            <subfield code="a">
                                <!-- 2.02 -->
                                <xsl:for-each select="mods:namePart">
                                    <xsl:choose>
                                        <xsl:when test="@type='family' and following-sibling::mods:namePart[@type='given']">
                                            <xsl:value-of select="concat(.,', ')"/>
                                        </xsl:when>
                                        <xsl:otherwise><xsl:value-of select="."/><xsl:if test="following-sibling::*"><xsl:text> </xsl:text></xsl:if></xsl:otherwise>
                                    </xsl:choose>
                                </xsl:for-each>
                            </subfield>
                            <!-- v3 role -->
                            <xsl:for-each select="mods:role/mods:roleTerm[@type='code']">
                                <subfield code="4">
                                    <xsl:value-of select="."/>
                                </subfield>
                            </xsl:for-each>
                            <xsl:apply-templates select="*[position()>1]"/>
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:when>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="mods:subject[local-name(*[1])='titleInfo']">
        <xsl:call-template name="datafield">
            <xsl:with-param name="tag">630</xsl:with-param>
            <xsl:with-param name="ind1"><xsl:value-of select="string-length(mods:titleInfo/mods:nonSort)"/></xsl:with-param>
            <xsl:with-param name="ind2"><xsl:call-template name="authorityInd"/></xsl:with-param>
            <xsl:with-param name="subfields">
                <xsl:for-each select="mods:titleInfo">
                    <xsl:call-template name="titleInfo"/>
                </xsl:for-each>
                <xsl:apply-templates select="*[position()>1]"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
        
    <xsl:template match="mods:subject[local-name(*[1])='temporal']">
        <xsl:call-template name="datafield">
            <xsl:with-param name="tag">650</xsl:with-param>
            <xsl:with-param name="subfields">
                <subfield code="a">
                    <xsl:value-of select="*[1]"/>
                </subfield>
                <xsl:apply-templates select="*[position()>1]"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
        
    <!-- Welche Ind2-Nummer "4"? -->
    <!-- Grab all subject from tag "topic" except local subject "topic"(=Grobklassifikation) -->
    <xsl:template match="mods:subject[local-name(*[1])='topic' and not(@authority='local')]">
        <datafield tag="650" ind1=" " ind2="0">
            <subfield code="a">
                <xsl:value-of select="*[1]"/>
            </subfield>
            <xsl:apply-templates select="*[position()>1]"/>
        </datafield>
    </xsl:template>
    
    <xsl:template match="mods:subject[local-name(*[1])='geographic']">
        <xsl:call-template name="datafield">
            <xsl:with-param name="tag">651</xsl:with-param>
            <xsl:with-param name="ind1"> </xsl:with-param>
            <xsl:with-param name="ind2"><xsl:call-template name="authorityInd"/></xsl:with-param>
            <xsl:with-param name="subfields">
                <subfield code="a">
                    <xsl:value-of select="*[1]"/>
                </subfield>
                <xsl:apply-templates select="*[position()>1]"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    
    <!-- Grobklassifikation ToDo:in welches MARC-Feld 655? -->
    <xsl:template match="mods:subject[@authority='local'][local-name(*[1])='topic']">
        <datafield tag="655" ind1=" " ind2="0">
            <subfield code="a">
                <xsl:value-of select="*[1]"/>
            </subfield>
            <xsl:apply-templates select="*[position()>1]"/>
        </datafield>
    </xsl:template>
    
    <xsl:template match="mods:subject[local-name(*[1])='genre']">
        <xsl:call-template name="datafield">
            <xsl:with-param name="tag">655</xsl:with-param>
            <xsl:with-param name="subfields">
                <subfield code="a">
                    <xsl:value-of select="*[1]"/>
                </subfield>
                <xsl:apply-templates select="*[position()>1]"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="mods:subject/mods:genre">
        <subfield code="v">
            <xsl:choose>
                <xsl:when test="text()[substring(., string-length()) ='.']">
                    <xsl:value-of select="substring(., 1, string-length() - 1)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </subfield>
    </xsl:template>
    
    <xsl:template match="mods:subject/mods:topic">
        <subfield code="x">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    
    <xsl:template match="mods:subject/mods:temporal">
        <subfield code="y">
            <xsl:value-of select="."/>
        </subfield>
    </xsl:template>
    
    <xsl:template match="mods:subject/mods:geographic">
        <subfield code="z">
            <xsl:choose>
                <xsl:when test="text()[substring(., string-length()) ='.']">
                    <xsl:value-of select="substring(., 1, string-length() - 1)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </subfield>
    </xsl:template>
    

    <!-- Name elements -->
    <!-- v3 role-->
    <!-- 3.03 -->
    <xsl:template match="mods:name[@type='personal'][mods:role/mods:roleTerm[@type='text']='creator' or mods:role/mods:roleTerm[@type='code']='cre']">
        <xsl:call-template name="datafield">
            <xsl:with-param name="tag">100</xsl:with-param>
            <xsl:with-param name="ind1">1</xsl:with-param>
            <xsl:with-param name="subfields">
                <marc:subfield code="a">
                    <!-- 2.02 -->
                    <xsl:for-each select="mods:namePart[not(@type = 'termsOfAddress') and not(@type='date')]">
                        <xsl:choose>
                            <xsl:when test="@type='family' and following-sibling::mods:namePart[@type='given']">
                                <xsl:value-of select="concat(.,', ')"/>
                            </xsl:when>
                            <xsl:otherwise><xsl:value-of select="."/><xsl:if test="following-sibling::*"><xsl:text> </xsl:text></xsl:if></xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </marc:subfield>
                <!-- v3 termsOfAddress -->
                <xsl:for-each select="mods:namePart[@type='termsOfAddress']">
                    <marc:subfield code="c">
                        <xsl:value-of select="."/>
                    </marc:subfield>
                </xsl:for-each>
                <xsl:for-each select="mods:namePart[@type='date']">
                    <marc:subfield code="d">
                        <xsl:value-of select="."/>
                    </marc:subfield>
                </xsl:for-each>
                <!-- v3 role -->
                <xsl:for-each select="mods:role/mods:roleTerm[@type='text']">
                    <marc:subfield code="e">
                        <xsl:value-of select="."/>
                    </marc:subfield>
                </xsl:for-each>
                <xsl:for-each select="mods:role/mods:roleTerm[@type='code']">
                    <marc:subfield code="4">
                        <xsl:value-of select="."/>
                    </marc:subfield>
                </xsl:for-each>
                <xsl:for-each select="mods:affiliation">
                    <marc:subfield code="u">
                        <xsl:value-of select="."/>
                    </marc:subfield>
                </xsl:for-each>
                <xsl:for-each select="mods:description">
                    <marc:subfield code="g">
                        <xsl:value-of select="."/>
                    </marc:subfield>
                </xsl:for-each>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    <!-- v3 role -->
    <xsl:template match="mods:name[@type='corporate'][mods:role/mods:roleTerm[@type='text']='creator' or mods:role/mods:roleTerm[@type='code']='cre']">
        <xsl:call-template name="datafield">
            <xsl:with-param name="tag">110</xsl:with-param>
            <xsl:with-param name="ind1">2</xsl:with-param>
            <xsl:with-param name="subfields">
                <marc:subfield code="a">
                    <xsl:value-of select="mods:namePart[1]"/>
                </marc:subfield>
                <xsl:for-each select="mods:namePart[position()>1]">
                    <marc:subfield code="b">
                        <xsl:value-of select="."/>
                    </marc:subfield>
                </xsl:for-each>
                <!-- v3 role -->
                <xsl:for-each select="mods:role/mods:roleTerm[@type='text']">
                    <marc:subfield code="e">
                        <xsl:value-of select="."/>
                    </marc:subfield>
                </xsl:for-each>
                <xsl:for-each select="mods:role/mods:roleTerm[@type='code']">
                    <marc:subfield code="4">
                        <xsl:value-of select="."/>
                    </marc:subfield>
                </xsl:for-each>
                <xsl:for-each select="mods:description">
                    <marc:subfield code="g">
                        <xsl:value-of select="."/>
                    </marc:subfield>
                </xsl:for-each>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    <!-- v3 role -->
    <xsl:template match="mods:name[@type='conference'][mods:role/mods:roleTerm[@type='text']='creator' or mods:role/mods:roleTerm[@type='code']='cre']">
        <xsl:call-template name="datafield">
            <xsl:with-param name="tag">111</xsl:with-param>
            <xsl:with-param name="ind1">2</xsl:with-param>
            <xsl:with-param name="subfields">
                <marc:subfield code="a">
                    <xsl:value-of select="mods:namePart[1]"/>
                </marc:subfield>
                <!-- v3 role -->
                <xsl:for-each select="mods:role/mods:roleTerm[@type='code']">
                    <marc:subfield code="4">
                        <xsl:value-of select="."/>
                    </marc:subfield>
                </xsl:for-each>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    <!-- v3 role -->
    <xsl:template match="mods:name[@type='personal'][mods:role/mods:roleTerm[@type='text']!='creator' or mods:role/mods:roleTerm[@type='code']!='cre' or not(mods:role)]">
        <xsl:call-template name="datafield">
            <xsl:with-param name="tag">700</xsl:with-param>
            <xsl:with-param name="ind1">1</xsl:with-param>
            <xsl:with-param name="subfields">
                <marc:subfield code="a">
                    <!-- 2.02 -->
                    <xsl:for-each select="mods:namePart[not(@type = 'termsOfAddress') and not(@type='date')]">
                        <xsl:choose>
                            <xsl:when test="@type='family' and following-sibling::mods:namePart[@type='given']">
                                <xsl:value-of select="concat(.,', ')"/>
                            </xsl:when>
                            <xsl:otherwise><xsl:value-of select="."/><xsl:if test="following-sibling::*"><xsl:text> </xsl:text></xsl:if></xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </marc:subfield>
                <!-- v3 termsofAddress -->
                <xsl:for-each select="mods:namePart[@type='termsOfAddress']">
                    <marc:subfield code="c">
                        <xsl:value-of select="."/>
                    </marc:subfield>
                </xsl:for-each>
                <xsl:for-each select="mods:namePart[@type='date']">
                    <marc:subfield code="d">
                        <xsl:value-of select="."/>
                    </marc:subfield>
                </xsl:for-each>
                <!-- v3 role -->
                <xsl:for-each select="mods:role/mods:roleTerm[@type='text']">
                    <marc:subfield code="e">
                        <xsl:value-of select="."/>
                    </marc:subfield>
                </xsl:for-each>
                <xsl:for-each select="mods:role/mods:roleTerm[@type='code']">
                    <marc:subfield code="4">
                        <xsl:value-of select="."/>
                    </marc:subfield>
                </xsl:for-each>
                <xsl:for-each select="mods:affiliation">
                    <marc:subfield code="u">
                        <xsl:value-of select="."/>
                    </marc:subfield>
                </xsl:for-each>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    <!-- v3 role -->
    <xsl:template match="mods:name[@type='corporate'][mods:role/mods:roleTerm[@type='text']!='creator' or mods:role/mods:roleTerm[@type='code']!='cre' or not(mods:role)]">
        <xsl:call-template name="datafield">
            <xsl:with-param name="tag">710</xsl:with-param>
            <xsl:with-param name="ind1">2</xsl:with-param>
            <xsl:with-param name="subfields">
                <subfield code="a">
                    <!-- 1/04 fix -->
                    <xsl:value-of select="mods:namePart[1]"/>
                </subfield>
                <xsl:for-each select="mods:namePart[position()>1]">
                    <subfield code="b"><xsl:value-of select="."/></subfield>
                </xsl:for-each><!-- v3 role -->
                <xsl:for-each select="mods:role/mods:roleTerm[@type='text']">
                    <subfield code="e">
                        <xsl:value-of select="."/>
                    </subfield>
                </xsl:for-each>
                <xsl:for-each select="mods:role/mods:roleTerm[@type='code']">
                    <subfield code="4">
                        <xsl:value-of select="."/>
                    </subfield>
                </xsl:for-each>
                <xsl:for-each select="mods:description">
                    <subfield code="g">
                        <xsl:value-of select="."/>
                    </subfield>
                </xsl:for-each>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    <!-- v3 role -->
    <xsl:template match="mods:name[@type='conference'][mods:role/mods:roleTerm[@type='text']!='creator' or mods:role/mods:roleTerm[@type='code']!='cre' or not(mods:role)]">
        <xsl:call-template name="datafield">
            <xsl:with-param name="tag">711</xsl:with-param>
            <xsl:with-param name="ind1">2</xsl:with-param>
            <xsl:with-param name="subfields">
                <marc:subfield code="a">
                    <xsl:value-of select="mods:namePart[1]"/>
                </marc:subfield>
                <!-- v3 role -->
                <xsl:for-each select="mods:role/mods:roleTerm[@type='code']">
                    <marc:subfield code="4">
                        <xsl:value-of select="."/>
                    </marc:subfield>
                </xsl:for-each>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    <!-- ToDO:  -->
    <xsl:template match="mods:name[not(@type)][mods:role/mods:roleTerm[@type='text']='creator' or mods:role/mods:roleTerm[@type='code']='cre']">
        <xsl:call-template name="datafield">
            <xsl:with-param name="tag">720</xsl:with-param>
            <xsl:with-param name="subfields">
                <subfield code="a">
                    <!-- 2.02 -->
                    <xsl:for-each select="mods:namePart">
                        <xsl:choose>
                            <xsl:when test="@type='family' and following-sibling::mods:namePart[@type='given']">
                                <xsl:value-of select="concat(.,', ')"/>
                            </xsl:when>
                            <xsl:otherwise><xsl:value-of select="."/><xsl:if test="following-sibling::*"><xsl:text> </xsl:text></xsl:if></xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </subfield>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    

</xsl:stylesheet>
