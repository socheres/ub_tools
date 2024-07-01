<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xlink="http://www.w3.org/1999/xlink"
	xmlns:mods="http://www.loc.gov/mods/v3"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:marc="http://www.loc.gov/MARC21/slim"
	exclude-result-prefixes="mods xlink">
<!--
	Maintenance note: For each revision, change the content of <datafield tag="500" ind1=" " ind2=" "><subfield code="a"> to reflect the new revision number.
	MODS v3.7  (Revision 3.06) 20200514

	Revision 3.06 - Add mods:genre/@authority="marcgt" = comic or graphic novel as 008/BK code='c' - 2020/05/14 ws
	Revision 3.05 - Upgraded to MODS 3.7 from MODS 3.6 - 2020/05/14 ws
	Revision 3.04 - Update genre output to correctly match mapping - 2020/05/14 ws
	Revision 3.03 - Fix bug in mods:name output, incorrectly outputting 100 as 720 - 2020/04/16 ws
	Revision 3.02 - Upgraded to MODS 3.6 from MODS 3.5 - 2020/04/14 ws
	Revision 3.01 - fix type in mods:hierarchicalGeographic - 2020/04/13 ws
	Revision 3.00 - Upgraded to MODS 3.5 from MODS 3.4 - 2020/03/05 ws
					Add mapping for originInfo/@eventType
					Update ind2 value for genre @authority="marcmuscomp" and @type="musical composition"
-->

	<xsl:include href="MARC21slimUtils-pts.xsl"/>

	<xsl:output method="xml" indent="yes" encoding="UTF-8"/>

	<xsl:template match="/">
			<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="mods:modsCollection">
		<collection xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
			<xsl:apply-templates/>
		</collection>
	</xsl:template>
	
	<xsl:template match="*"/>
	
	<xsl:strip-space elements="*"/>
	
	<xsl:template match="mods:targetAudience[@authority='marctarget']" mode="ctrl008">
		<xsl:choose>
		<xsl:when test=".='adolescent'">d</xsl:when>
		<xsl:when test=".='adult'">e</xsl:when>
		<xsl:when test=".='general'">g</xsl:when>
		<xsl:when test=".='juvenile'">j</xsl:when>
		<xsl:when test=".='preschool'">a</xsl:when>
		<xsl:when test=".='specialized'">f</xsl:when>
		<xsl:otherwise><xsl:text>|</xsl:text></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="mods:typeOfResource" mode="ctrl008">
		<xsl:choose>
			<xsl:when test="text()='text' and @manuscript='yes'">BK</xsl:when>
			<xsl:when test="text()='text'">
			<xsl:choose>
				<xsl:when test="../mods:originInfo/mods:issuance='monographic'">BK</xsl:when>
				<xsl:when test="../mods:originInfo/mods:issuance='continuing'">SE</xsl:when>
				<!-- 3.04 -->
				<xsl:when test="../mods:originInfo/mods:issuance='serial'">SE</xsl:when>
			</xsl:choose>
			</xsl:when>
			<xsl:when test="text()='cartographic' and @manuscript='yes'">MP</xsl:when>
			<xsl:when test="text()='cartographic'">MP</xsl:when>
			<xsl:when test="text()='notated music' and @manuscript='yes'">MU</xsl:when>
			<xsl:when test="text()='notated music'">MU</xsl:when>
			<xsl:when test="text()='sound recording'">MU</xsl:when>
			<!-- v3 musical/non -->
			<xsl:when test="text()='sound recording-nonmusical'">MU</xsl:when>
			<xsl:when test="text()='sound recording-musical'">MU</xsl:when>
			<xsl:when test="text()='still image'">VM</xsl:when>
			<xsl:when test="text()='moving image'">VM</xsl:when>
			<xsl:when test="text()='three dimensional object'">VM</xsl:when>
			<xsl:when test="text()='software, multimedia'">CF</xsl:when>
			<xsl:when test="text()='mixed material'">MM</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="controlField008-24-27">
		<xsl:variable name="chars">
			<!-- 3.04 -->
			<xsl:for-each select="mods:genre[@authority='marcgt']">
				<xsl:choose>
					<!-- 3.04 -->
					<xsl:when test=".='abstract or summary'">a</xsl:when>
					<xsl:when test=".='bibliography'">b</xsl:when>
					<xsl:when test=".='catalog'">c</xsl:when>
					<!-- 3.04 -->
					<xsl:when test=".='comic or graphic novel'">6</xsl:when>
					<xsl:when test=".='dictionary'">d</xsl:when>
					<xsl:when test=".='directory'">r</xsl:when>
					<xsl:when test=".='discography'">k</xsl:when>
					<xsl:when test=".='encyclopedia'">e</xsl:when>
					<xsl:when test=".='filmography'">q</xsl:when>
					<xsl:when test=".='handbook'">f</xsl:when>
					<xsl:when test=".='index'">i</xsl:when>
					<xsl:when test=".='law report or digest'">w</xsl:when>
					<xsl:when test=".='legal article'">g</xsl:when>
					<xsl:when test=".='legal case and case notes'">v</xsl:when>
					<xsl:when test=".='legislation'">l</xsl:when>
					<!-- 3.04 -->
					<xsl:when test=".='offprint'">2</xsl:when>
					<xsl:when test=".='patent'">j</xsl:when>
					<xsl:when test=".='programmed text'">p</xsl:when>
					<xsl:when test=".='review'">o</xsl:when>
					<!-- 3.04 -->
					<xsl:when test=".='standard or specification'">u</xsl:when>
					<xsl:when test=".='statistics'">s</xsl:when>
					<xsl:when test=".='survey of literature'">n</xsl:when>
					<xsl:when test=".='technical report'">t</xsl:when>
					<xsl:when test=".='theses'">m</xsl:when>
					<xsl:when test=".='treaty'">z</xsl:when>
					<!-- 3.04 -->
					<xsl:when test=".='yearbook'">y</xsl:when>
				</xsl:choose>
			</xsl:for-each>
		</xsl:variable>
		<xsl:call-template name="makeSize">
			<xsl:with-param name="string" select="$chars"/>
			<xsl:with-param name="length" select="4"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="controlField008-30-31">
		<xsl:variable name="chars">
			<!-- 3.04 -->
			<xsl:for-each select="mods:genre[@authority='marcgt']">
				<xsl:choose>
					<!-- 3.04 -->
					<xsl:when test=".='autobiography'">a</xsl:when>
					<xsl:when test=".='biography'">b</xsl:when>
					<xsl:when test=".='conference publication'">c</xsl:when>
					<xsl:when test=".='drama'">d</xsl:when>
					<xsl:when test=".='essay'">e</xsl:when>
					<xsl:when test=".='fiction'">f</xsl:when>
					<xsl:when test=".='folktale'">o</xsl:when>
					<xsl:when test=".='history'">h</xsl:when>
					<xsl:when test=".='humor, satire'">k</xsl:when>
					<xsl:when test=".='instruction'">i</xsl:when>
					<xsl:when test=".='interview'">t</xsl:when>
					<xsl:when test=".='language instruction'">j</xsl:when>
					<xsl:when test=".='memoir'">m</xsl:when>
					<!-- 3.04 -->
					<xsl:when test=".='poetry'">p</xsl:when>
					<xsl:when test=".='rehersal'">r</xsl:when>
					<xsl:when test=".='reporting'">g</xsl:when>
					<xsl:when test=".='sound'">s</xsl:when>
					<xsl:when test=".='speech'">l</xsl:when>
				</xsl:choose>
			</xsl:for-each>
		</xsl:variable>
		<xsl:call-template name="makeSize">
			<xsl:with-param name="string" select="$chars"/>
			<xsl:with-param name="length" select="2"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="makeSize">
		<xsl:param name="string"/>
		<xsl:param name="length"/>
		<xsl:variable name="nstring" select="normalize-space($string)"/>
		<xsl:variable name="nstringlength" select="string-length($nstring)"/>
		<xsl:choose>
			<xsl:when test="$nstringlength&gt;$length">
				<xsl:value-of select="substring($nstring,1,$length)"/>
			</xsl:when>
			<xsl:when test="$nstringlength&lt;$length">
				<xsl:value-of select="$nstring"/>
				<xsl:call-template name="buildSpaces">
					<xsl:with-param name="spaces" select="$length - $nstringlength"/>
					<xsl:with-param name="char">|</xsl:with-param>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$nstring"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="mods:mods">
		<collection xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
			<record>
				<xsl:choose>
					<xsl:when test="parent::mods:modsCollection"/>
					<xsl:otherwise>
					</xsl:otherwise>
				</xsl:choose>
				<leader>
					<!-- 00-04 -->
					<xsl:text>     </xsl:text>
					<!-- 05 -->
					<xsl:text>c</xsl:text>
					<!-- 06 -->
					<!-- 2.01 -->
					<xsl:choose>
						<xsl:when test="mods:typeOfResource[1]='text'">a</xsl:when>
						<xsl:when test="mods:typeOfResource[1]='text' and @manuscript='yes'">t</xsl:when>
						<xsl:when test="mods:typeOfResource[1]='cartographic' and @manuscript='yes'">f</xsl:when>
						<xsl:when test="mods:typeOfResource[1]='cartographic'">e</xsl:when>
						<xsl:when test="mods:typeOfResource[1]='notated music' and @manuscript='yes'">d</xsl:when>
						<xsl:when test="mods:typeOfResource[1]='notated music'">c</xsl:when>
						<!-- v3 musical/non -->
						<xsl:when test="mods:typeOfResource[1]='sound recording-nonmusical'">i</xsl:when>
						<!-- genres audio = sound recording-nonmusical -->
						<xsl:when test="mods:physicalDescription/mods:form[@authority='local']='Audio'">i</xsl:when>
						<xsl:when test="mods:typeOfResource[1]='sound recording'">j</xsl:when>
						<xsl:when test="mods:typeOfResource[1]='sound recording-musical'">j</xsl:when>
						<xsl:when test="mods:typeOfResource[1]='still image'">k</xsl:when>
						<xsl:when test="mods:typeOfResource[1]='moving image'">g</xsl:when>
						<xsl:when test="mods:typeOfResource[1]='three dimensional object'">r</xsl:when>
						<xsl:when test="mods:typeOfResource[1]='software, multimedia'">m</xsl:when>
						<xsl:when test="mods:typeOfResource[1]='mixed material'">p</xsl:when>
						<xsl:otherwise>a</xsl:otherwise>
					</xsl:choose>
					<!-- 07 -->
					<xsl:choose>
						<xsl:when test="mods:originInfo/mods:issuance='monographic'">m</xsl:when>
						<xsl:when test="mods:originInfo/mods:issuance='continuing'">s</xsl:when>
						<xsl:when test="mods:typeOfResource/@collection='yes'">c</xsl:when>
						<!-- v3.4 Added mapping for single unit, serial, integrating resource, multipart monograph  -->
						<xsl:when test="mods:originInfo/mods:issuance='multipart monograph'">m</xsl:when>
						<xsl:when test="mods:originInfo/mods:issuance='single unit'">m</xsl:when>
						<xsl:when test="mods:originInfo/mods:issuance='integrating resource'">i</xsl:when>
						<xsl:when test="mods:originInfo/mods:issuance='serial'">s</xsl:when>
						<!-- ubtue -->
						<xsl:when test="mods:physicalDescription/mods:form[@authority='local']='Book'">m</xsl:when>
						<xsl:otherwise>m</xsl:otherwise>
					</xsl:choose>
					<!-- 08 -->
					<xsl:text> </xsl:text>
					<!-- 09 -->
					<xsl:text>a</xsl:text>
					<!-- 10 -->
					<xsl:text>2</xsl:text>
					<!-- 11 -->
					<xsl:text>2</xsl:text>
					<!-- 12-16 -->
					<xsl:text>     </xsl:text>
					<!-- 17 -->
					<xsl:text> </xsl:text>
					<!-- 18 -->
					<xsl:text> </xsl:text>
					<!-- 19 -->
					<xsl:text> </xsl:text>
					<!-- 20-23 -->
					<xsl:text>4500</xsl:text>
				</leader>
				<xsl:call-template name="controlRecordInfo"/>
				<!-- 3.04 -->
				<xsl:if test="mods:genre[@authority='marcgt']='atlas'">
					<controlfield tag="007">ad||||||</controlfield>
				</xsl:if>
				<xsl:if test="mods:genre[@authority='marcgt']='model'">
					<controlfield tag="007">aq||||||</controlfield>
				</xsl:if>
				<xsl:if test="mods:genre[@authority='marcgt']='remote sensing image'">
					<controlfield tag="007">ar||||||</controlfield>
				</xsl:if>
				<xsl:if test="mods:genre[@authority='marcgt']='map'">
					<controlfield tag="007">aj||||||</controlfield>
				</xsl:if>
				<xsl:if test="mods:genre[@authority='marcgt']='globe'">
					<controlfield tag="007">d|||||</controlfield>
				</xsl:if>
				<!-- ubtue 007 -->
				<xsl:if test=" mods:physicalDescription/mods:form[@authority='local']='Book' and mods:physicalDescription/mods:extent[@unit='digital-images'] ">
					<controlfield tag="007">cr uuu---uuuuu</controlfield>
				</xsl:if>
				
				<controlfield tag="008">
					<xsl:variable name="typeOf008"><xsl:apply-templates mode="ctrl008" select="mods:typeOfResource"/></xsl:variable>
					<!-- 00-05 -->
					<xsl:choose>
						<!-- 1/04 fix -->
						<xsl:when test="mods:recordInfo/mods:recordContentSource[@authority='marcorg']">
							<xsl:value-of select="mods:recordInfo/mods:recordCreationDate[@encoding='marc']"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text>      </xsl:text>
						</xsl:otherwise>
					</xsl:choose>
					<!-- 06 -->
					<xsl:choose>
						<xsl:when test="mods:originInfo/mods:issuance='monographic' and count(mods:originInfo/mods:dateIssued)=1">s</xsl:when>
						<!-- v3 questionable -->
						<xsl:when test="mods:originInfo/mods:dateIssued[@qualifier='questionable']">q</xsl:when>
						<xsl:when test="mods:originInfo/mods:issuance='monographic' and mods:originInfo/mods:dateIssued[@point='start'] and mods:originInfo/mods:dateIssued[@point='end']">m</xsl:when>
						<xsl:when test="mods:originInfo/mods:issuance='continuing' and mods:originInfo/mods:dateIssued[@point='end' and @encoding='marc']='9999'">c</xsl:when>
						<xsl:when test="mods:originInfo/mods:issuance='continuing' and mods:originInfo/mods:dateIssued[@point='end' and @encoding='marc']='uuuu'">u</xsl:when>
						<xsl:when test="mods:originInfo/mods:issuance='continuing' and mods:originInfo/mods:dateIssued[@point='end' and @encoding='marc']">d</xsl:when>
						<xsl:when test="not(mods:originInfo/mods:issuance) and mods:originInfo/mods:dateIssued">s</xsl:when>
						<!-- v3 copyright date-->
						<xsl:when test="mods:originInfo/mods:copyrightDate">s</xsl:when>
						<xsl:otherwise>|</xsl:otherwise>
					</xsl:choose>
					<!-- 07-14          -->
					<!-- 07-10 -->
					<xsl:choose>
						<xsl:when test="mods:originInfo/mods:dateIssued[@point='start' and @encoding='marc']">
							<xsl:value-of select="mods:originInfo/mods:dateIssued[@point='start' and @encoding='marc']"/>
						</xsl:when>
						<xsl:when test="mods:originInfo/mods:dateIssued[@encoding='marc']">
							<xsl:value-of select="mods:originInfo/mods:dateIssued[@encoding='marc']"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text>    </xsl:text>
						</xsl:otherwise>
					</xsl:choose>
					<!-- 11-14 -->
					<xsl:choose>
						<xsl:when test="mods:originInfo/mods:dateIssued[@point='end' and @encoding='marc']">
							<xsl:value-of select="mods:originInfo/mods:dateIssued[@point='end' and @encoding='marc']"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text>    </xsl:text>
						</xsl:otherwise>
					</xsl:choose>
					<!-- 15-17 -->
					<xsl:choose>
						<!-- v3 place -->
						<xsl:when test="mods:originInfo/mods:place/mods:placeTerm[@type='code'][@authority='marccountry']">
							<!-- v3 fixed marc:code reference and authority change-->
							<xsl:value-of select="mods:originInfo/mods:place/mods:placeTerm[@type='code'][@authority='marccountry']"/>
							<!-- 1/04 fix -->
							<xsl:if test="string-length(mods:originInfo/mods:place/mods:placeTerm[@type='code'][@authority='marccountry'])=2">
								<xsl:text> </xsl:text>
							</xsl:if>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text>   </xsl:text>
						</xsl:otherwise>
					</xsl:choose>
					<!-- 18-20 -->
					<xsl:text>|||</xsl:text>
					<!-- 21 -->
					<xsl:choose>
						<xsl:when test="$typeOf008='SE'">
							<xsl:choose>
								<!-- 3.04 -->
								<xsl:when test="mods:genre[@authority='marcgt']='database'">d</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='loose-leaf'">l</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='newspaper'">n</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='periodical'">p</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='series'">m</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='web site'">w</xsl:when>
								<xsl:otherwise>|</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise>|</xsl:otherwise>
					</xsl:choose>
					<!-- 22 -->
					<!-- 1/04 fix -->
					<xsl:choose>
						<xsl:when test="mods:targetAudience[@authority='marctarget']">
							<xsl:apply-templates mode="ctrl008" select="mods:targetAudience[@authority='marctarget']"/>
						</xsl:when>
						<xsl:otherwise>|</xsl:otherwise>
					</xsl:choose>
					<!-- 23 -->
					<xsl:choose>
						<xsl:when test="$typeOf008='BK' or $typeOf008='MU' or $typeOf008='SE' or $typeOf008='MM'">
							<xsl:choose>
								<xsl:when test="mods:physicalDescription/mods:form[@authority='marcform']='braille'">f</xsl:when>
								<xsl:when test="mods:physicalDescription/mods:form[@authority='marcform']='electronic'">s</xsl:when>
								<xsl:when test="mods:physicalDescription/mods:form[@authority='marcform']='microfiche'">b</xsl:when>
								<xsl:when test="mods:physicalDescription/mods:form[@authority='marcform']='microfilm'">a</xsl:when>
								<xsl:when test="mods:physicalDescription/mods:form[@authority='marcform']='print'"><xsl:text> </xsl:text></xsl:when>
								<xsl:otherwise>|</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise>|</xsl:otherwise>
					</xsl:choose>
					<!-- 24-27 -->
					<xsl:choose>
						<xsl:when test="$typeOf008='BK'">
							<xsl:call-template name="controlField008-24-27"/>
						</xsl:when>
						<xsl:when test="$typeOf008='MP'">
							<xsl:text>|</xsl:text>
							<xsl:choose>
								<!-- 3.04 -->
								<xsl:when test="mods:genre[@authority='marcgt']='atlas'">e</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='globe'">d</xsl:when>
								<xsl:otherwise>|</xsl:otherwise>
							</xsl:choose>
							<xsl:text>||</xsl:text>
						</xsl:when>
						<xsl:when test="$typeOf008='CF'">
							<xsl:text>||</xsl:text>
							<xsl:choose>
								<!-- 3.04 -->
								<xsl:when test="mods:genre[@authority='marcgt']='database'">e</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='font'">f</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='game'">g</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='numerical data'">a</xsl:when>
								<!-- 3.04 -->
								<xsl:when test="mods:genre[@authority='marcgt']='numeric data'">a</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='sound'">h</xsl:when>
								<xsl:otherwise>|</xsl:otherwise>
							</xsl:choose>
							<xsl:text>|</xsl:text>
						</xsl:when>
						<!-- 3.04 -->
						<xsl:when test="$typeOf008='SE'">
							<xsl:text>|||</xsl:text>
							<xsl:choose>
								<!-- 3.04 -->
								<xsl:when test="mods:genre[@authority='marcgt']='abstract or summary'">a</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='bibliography'">b</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='calendar'">5</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='catalog'">c</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='comic or graphic novel'">6</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='dictionary'">d</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='directory'">r</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='discography'">k</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='encyclopedia'">e</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='filmography'">q</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='handbook'">f</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='index'">i</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='law report or digest'">w</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='legal article'">g</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='legal case and case notes'">v</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='legislation'">l</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='programmed text'">p</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='review'">o</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='statistics'">s</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='survey of literature'">n</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='technical report'">t</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='theses'">m</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='treaty'">z</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='yearbook'">y</xsl:when>
								<xsl:otherwise>|</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text>||||</xsl:text>
						</xsl:otherwise>
					</xsl:choose>
					<!-- 28 -->
					<xsl:text>|</xsl:text>
					<!-- 29 -->
					<xsl:choose>
						<xsl:when test="$typeOf008='BK' or $typeOf008='SE'">
							<xsl:choose>
								<!-- 3.04 -->
								<xsl:when test="mods:genre[@authority='marcgt']='conference publication'">1</xsl:when>
								<xsl:otherwise>|</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:when test="$typeOf008='MP' or $typeOf008='VM'">
							<xsl:choose>
							<xsl:when test="mods:physicalDescription/mods:form='braille'">f</xsl:when>
							<xsl:when test="mods:physicalDescription/mods:form='electronic'">m</xsl:when>
							<xsl:when test="mods:physicalDescription/mods:form='microfiche'">b</xsl:when>
							<xsl:when test="mods:physicalDescription/mods:form='microfilm'">a</xsl:when>
							<xsl:when test="mods:physicalDescription/mods:form='print'"><xsl:text> </xsl:text></xsl:when>
							<xsl:otherwise>|</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise>|</xsl:otherwise>
					</xsl:choose>
					<!-- 30-31 -->
					<xsl:choose>
						<xsl:when test="$typeOf008='MU'">
							<xsl:call-template name="controlField008-30-31"/>
						</xsl:when>
						<xsl:when test="$typeOf008='BK'">
							<xsl:choose>
								<!-- 3.04 -->
								<xsl:when test="mods:genre[@authority='marcgt']='festschrift'">1</xsl:when>
								<xsl:otherwise>|</xsl:otherwise>
							</xsl:choose>
							<xsl:text>|</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text>||</xsl:text>
						</xsl:otherwise>
					</xsl:choose>
					<!-- 32 -->
					<xsl:text>|</xsl:text>
					<!-- 33 -->
					<xsl:choose>
						<xsl:when test="$typeOf008='VM'">
							<xsl:choose>
								<!-- 3.04 -->
								<xsl:when test="mods:genre[@authority='marcgt']='art original'">a</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='art reproduction'">c</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='chart'">n</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='diorama'">d</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='filmstrip'">f</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='flash card'">o</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='graphic'">k</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='kit'">b</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='technical drawing'">l</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='slide'">s</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='realia'">r</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='picture'">i</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='motion picture'">m</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='model'">q</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='microscope slide'">p</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='toy'">w</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='transparency'">t</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='videorecording'">v</xsl:when>
							<xsl:otherwise>|</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:when test="$typeOf008='BK'">
							<xsl:choose>
								<!-- 3.06 -->
								<xsl:when test="mods:genre[@authority='marcgt']='comic or graphic novel'">c</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='fiction'">1</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='essay'">e</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='drama'">d</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='humor, satire'">h</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='letter'">i</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='novel'">f</xsl:when>
								<!-- 3.04 -->
								<xsl:when test="mods:genre[@authority='marcgt']='poetry'">p</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='short story'">j</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='speech'">s</xsl:when>
							<xsl:otherwise>|</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise>|</xsl:otherwise>
					</xsl:choose>
					<!-- 34 -->
					<xsl:choose>
						<xsl:when test="$typeOf008='BK'">
							<xsl:choose>
								<!-- 3.04 -->
								<xsl:when test="mods:genre[@authority='marcgt']='autobiography'">a</xsl:when>
								<xsl:when test="mods:genre[@authority='marcgt']='biography'">d</xsl:when>
								<xsl:otherwise>|</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise>|</xsl:otherwise>
					</xsl:choose>
					<!-- 35-37 -->
					<xsl:choose>
					<!-- v3 language -->
						<xsl:when test="mods:language/mods:languageTerm[@authority='iso639-2b']">
							<!-- 2.01 -->
							<xsl:value-of select="mods:language[mods:languageTerm[@authority='iso639-2b']][1]/mods:languageTerm[@authority='iso639-2b'][1]"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text>|||</xsl:text>
						</xsl:otherwise>
					</xsl:choose>
					<!-- 38-39 -->
					<xsl:text>||</xsl:text>
				</controlfield>
				<!-- 1/04 fix sort -->
				<xsl:call-template name="source"/>
				<xsl:apply-templates/>
				<xsl:if test="mods:classification[@authority='lcc']">
					<xsl:call-template name="lcClassification"/>
				</xsl:if>
				<!-- 852 - Location (R) -->
				<!-- 852 will override/add by "DE-Tue135" -->
				<xsl:choose>
					<xsl:when test="mods:location/mods:physicalLocation">
						<xsl:for-each select="mods:location/mods:physicalLocation">
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
				<datafield tag="912" ind1=" " ind2=" ">
					<subfield code="a">NOMM</subfield>
				</datafield>
				<!-- add collections tags for navigation 866 and Abrufzeichen 935 -->
                <xsl:choose>
                    <!-- Albert Andrew Fulton Manuscript Collection -->
                    <xsl:when test="matches(mods:note, '^the\s?albert\s?andrew', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Albert Andrew Fulton Manuscript Collection</xsl:text>                          
                            </subfield>
                        	<subfield code="2">
                        		<xsl:text>LOK</xsl:text>
                        	</subfield>
                        </datafield>
                        <datafield tag="935" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>PRTC</xsl:text>
                            </subfield>
                        	<subfield code="a">
                        		<xsl:text>afum</xsl:text>
                        	</subfield>
                            <subfield code="2">
                                <xsl:text>LOK</xsl:text>
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Ashbel Green Simonton Manuscript Collection -->
                    <xsl:when test="matches(mods:note, '^the\s?ashbel\s?green\s?simonton\s?manuscript\s?collection', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Ashbel Green Simonton Manuscript Collection</xsl:text>                          
                            </subfield>
                        	<subfield code="2">
                        		<xsl:text>LOK</xsl:text>
                        	</subfield>
                        </datafield>
                        <datafield tag="935" ind1=" " ind2=" ">
                        	<subfield code="a">
                        		<xsl:text>PRTC</xsl:text>
                        	</subfield>
                        	<subfield code="a">
                                <xsl:text>agsm</xsl:text>
                            </subfield>
                            <subfield code="2">
                                <xsl:text>LOK</xsl:text>
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Academy of Homiletics -->
                    <xsl:when test="matches(mods:note, 'academy\s?of\s?homiletics', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Academy of Homiletics</xsl:text>                          
                            </subfield>
                        	<subfield code="2">
                        		<xsl:text>LOK</xsl:text>
                        	</subfield>
                        </datafield>
                        <datafield tag="935" ind1=" " ind2=" ">
                        	<subfield code="a">
                        		<xsl:text>PRTC</xsl:text>
                        	</subfield>
                        	<subfield code="a">
                                <xsl:text>ahom</xsl:text>
                            </subfield>
                            <subfield code="2">
                                <xsl:text>LOK</xsl:text>
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- The Belle Sparr Luckett Manuscript Collection -->
                    <xsl:when test="matches(mods:note, '^the\s?belle\s?sparr\s?luckett\s?manuscript\s?collection', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Benson collection of hymnals and hymnology</xsl:text>                          
                            </subfield>
                        	<subfield code="2">
                        		<xsl:text>LOK</xsl:text>
                        	</subfield>
                        </datafield>
                        <datafield tag="935" ind1=" " ind2=" ">
                        	<subfield code="a">
                        		<xsl:text>PRTC</xsl:text>
                        	</subfield>
                        	<subfield code="a">
                                <xsl:text>bslm</xsl:text>
                            </subfield>
                            <subfield code="2">
                                <xsl:text>LOK</xsl:text>
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Benson collection of hymnals and hymnology -->
                    <xsl:when test="matches(mods:note, '^benson\s?collection\s?of\s?hymnals', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Benson collection of hymnals and hymnology</xsl:text>                          
                            </subfield>
                        	<subfield code="2">
                        		<xsl:text>LOK</xsl:text>
                        	</subfield>
                        </datafield>
                        <datafield tag="935" ind1=" " ind2=" ">
                        	<subfield code="a">
                        		<xsl:text>PRTC</xsl:text>
                        	</subfield>
                        	<subfield code="a">
                                <xsl:text>behy</xsl:text>
                            </subfield>
                            <subfield code="2">
                                <xsl:text>LOK</xsl:text>
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Beth Mardutho: The Syriac Institute -->
                    <xsl:when test="matches(//*[local-name()='collection_set'], '^bethmardutho', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Beth Mardutho: The Syriac Institute</xsl:text>                          
                            </subfield>
                        	<subfield code="2">
                        		<xsl:text>LOK</xsl:text>
                        	</subfield>
                        </datafield>
                        <datafield tag="935" ind1=" " ind2=" ">
                        	<subfield code="a">
                        		<xsl:text>PRTC</xsl:text>
                        	</subfield>
                        	<subfield code="a">
                                <xsl:text>bmsi</xsl:text>
                            </subfield>
                            <subfield code="2">
                                <xsl:text>LOK</xsl:text>
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Caleb Cook Baldwin Manuscript Collection -->
                    <xsl:when test="matches(mods:note, '^caleb\s?cook\s?baldwin\s?manuscript', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Caleb Cook Baldwin Manuscript Collection</xsl:text>                          
                            </subfield>
                        	<subfield code="2">
                        		<xsl:text>LOK</xsl:text>
                        	</subfield>
                        </datafield>
                        <datafield tag="935" ind1=" " ind2=" ">
                        	<subfield code="a">
                        		<xsl:text>PRTC</xsl:text>
                        	</subfield>
                        	<subfield code="a">
                                <xsl:text>cbam</xsl:text>
                            </subfield>
                            <subfield code="2">
                                <xsl:text>LOK</xsl:text>
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- David and Jane Wales Trumbull Manuscript Collection -->
                    <xsl:when test="matches(mods:note, '^david\s?and\s?jane\s?wales\s?trumbull', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#David and Jane Wales Trumbull Manuscript Collection</xsl:text>                          
                            </subfield>
                        	<subfield code="2">
                        		<xsl:text>LOK</xsl:text>
                        	</subfield>
                        </datafield>
                        <datafield tag="935" ind1=" " ind2=" ">
                        	<subfield code="a">
                        		<xsl:text>PRTC</xsl:text>
                        	</subfield>
                        	<subfield code="a">
                                <xsl:text>djwt</xsl:text>
                            </subfield>
                            <subfield code="2">
                                <xsl:text>LOK</xsl:text>
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
                        	<subfield code="2">
                        		<xsl:text>LOK</xsl:text>
                        	</subfield>
                        </datafield>
                        <datafield tag="935" ind1=" " ind2=" ">
                        	<subfield code="a">
                        		<xsl:text>PRTC</xsl:text>
                        	</subfield>
                        	<subfield code="a">
                                <xsl:text>ewam</xsl:text>
                            </subfield>
                            <subfield code="2">
                                <xsl:text>LOK</xsl:text>
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- The George H. Bowen Manuscript Collection -->
                    <xsl:when test="matches(mods:note, '^the\s?George\s?h\.?\s?bowen\s?manuscript', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#The George H. Bowen Manuscript Collection</xsl:text>                          
                            </subfield>
                        	<subfield code="2">
                        		<xsl:text>LOK</xsl:text>
                        	</subfield>
                        </datafield>
                        <datafield tag="935" ind1=" " ind2=" ">
                        	<subfield code="a">
                        		<xsl:text>PRTC</xsl:text>
                        	</subfield>
                        	<subfield code="a">
                                <xsl:text>ghbm</xsl:text>
                            </subfield>
                            <subfield code="2">
                                <xsl:text>LOK</xsl:text>
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- The Harry A. Rhodes Manuscript Collection -->
                    <xsl:when test="matches(mods:note, '^the\s?Harry\s?a\.?\s?rhodes\s?manuscript', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#The Harry A. Rhodes Manuscript Collection</xsl:text>                          
                            </subfield>
                        	<subfield code="2">
                        		<xsl:text>LOK</xsl:text>
                        	</subfield>
                        </datafield>
                        <datafield tag="935" ind1=" " ind2=" ">
                        	<subfield code="a">
                        		<xsl:text>PRTC</xsl:text>
                        	</subfield>
                        	<subfield code="a">
                                <xsl:text>harm</xsl:text>
                            </subfield>
                            <subfield code="2">
                                <xsl:text>LOK</xsl:text>
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- The James Watt Manuscript Collection -->
                    <xsl:when test="matches(mods:note, '^the\s?James\s?Watt\s?Manuscript\s?Collection', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#The James Watt Manuscript Collection</xsl:text>                          
                            </subfield>
                        	<subfield code="2">
                        		<xsl:text>LOK</xsl:text>
                        	</subfield>
                        </datafield>
                        <datafield tag="935" ind1=" " ind2=" ">
                        	<subfield code="a">
                        		<xsl:text>PRTC</xsl:text>
                        	</subfield>
                        	<subfield code="a">
                                <xsl:text>jwam</xsl:text>
                            </subfield>
                            <subfield code="2">
                                <xsl:text>LOK</xsl:text>
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- John A. Mackay collection -->
                    <xsl:when test="matches(mods:note, '^John\s?A\.\s?Mackay\s?Collection', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#John A. Mackay collection</xsl:text>                          
                            </subfield>
                        	<subfield code="2">
                        		<xsl:text>LOK</xsl:text>
                        	</subfield>
                        </datafield>
                        <datafield tag="935" ind1=" " ind2=" ">
                        	<subfield code="a">
                        		<xsl:text>PRTC</xsl:text>
                        	</subfield>
                        	<subfield code="a">
                                <xsl:text>jamc</xsl:text>
                            </subfield>
                            <subfield code="2">
                                <xsl:text>LOK</xsl:text>
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Langley Kitching South Africa/Madagascar Collection -->
                    <xsl:when test="matches(mods:note, '^Langley\s?Kitching\s?South\s?Africa', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Langley Kitching South Africa/Madagascar Collection</xsl:text>                          
                            </subfield>
                        	<subfield code="2">
                        		<xsl:text>LOK</xsl:text>
                        	</subfield>
                        </datafield>
                        <datafield tag="935" ind1=" " ind2=" ">
                        	<subfield code="a">
                        		<xsl:text>PRTC</xsl:text>
                        	</subfield>
                        	<subfield code="a">
                                <xsl:text>lksm</xsl:text>
                            </subfield>
                            <subfield code="2">
                                <xsl:text>LOK</xsl:text>
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
                        	<subfield code="2">
                        		<xsl:text>LOK</xsl:text>
                        	</subfield>
                        </datafield>
                        <datafield tag="935" ind1=" " ind2=" ">
                        	<subfield code="a">
                        		<xsl:text>PRTC</xsl:text>
                        	</subfield>
                        	<subfield code="a">
                                <xsl:text>ljam</xsl:text>
                            </subfield>
                            <subfield code="2">
                                <xsl:text>LOK</xsl:text>
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Michael S. Culbertson Manuscript Collection -->
                    <xsl:when test="matches(mods:note, '^Michael\s?S\.\s?Culbertson\s?Manuscript', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Michael S. Culbertson Manuscript Collection</xsl:text>                          
                            </subfield>
                        	<subfield code="2">
                        		<xsl:text>LOK</xsl:text>
                        	</subfield>
                        </datafield>
                        <datafield tag="935" ind1=" " ind2=" ">
                        	<subfield code="a">
                        		<xsl:text>PRTC</xsl:text>
                        	</subfield>
                        	<subfield code="a">
                                <xsl:text>mcum</xsl:text>
                            </subfield>
                            <subfield code="2">
                                <xsl:text>LOK</xsl:text>
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Missio Seminary Collection -->
                    <xsl:when test="matches(mods:name[@type='corporate']/mods:namePart, '^Missio\s?Seminary', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Missio Seminary Collection</xsl:text>                          
                            </subfield>
                        	<subfield code="2">
                        		<xsl:text>LOK</xsl:text>
                        	</subfield>
                        </datafield>
                        <datafield tag="935" ind1=" " ind2=" ">
                        	<subfield code="a">
                        		<xsl:text>PRTC</xsl:text>
                        	</subfield>
                        	<subfield code="a">
                                <xsl:text>mise</xsl:text>
                            </subfield>
                            <subfield code="2">
                                <xsl:text>LOK</xsl:text>
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Moffett Korea Collection -->
                    <xsl:when test="matches(mods:note, '^moffett\s?korea\s?collection', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Moffett Korea Collection</xsl:text>                          
                            </subfield>
                        	<subfield code="2">
                        		<xsl:text>LOK</xsl:text>
                        	</subfield>
                        </datafield>
                        <datafield tag="935" ind1=" " ind2=" ">
                        	<subfield code="a">
                        		<xsl:text>PRTC</xsl:text>
                        	</subfield>
                        	<subfield code="a">
                                <xsl:text>moko</xsl:text>
                            </subfield>
                            <subfield code="2">
                                <xsl:text>LOK</xsl:text>
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
                        	<subfield code="2">
                        		<xsl:text>LOK</xsl:text>
                        	</subfield>
                        </datafield>
                        <datafield tag="935" ind1=" " ind2=" ">
                        	<subfield code="a">
                        		<xsl:text>PRTC</xsl:text>
                        	</subfield>
                        	<subfield code="a">
                                <xsl:text>psam</xsl:text>
                            </subfield>
                            <subfield code="2">
                                <xsl:text>LOK</xsl:text>
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Payne Seminary/AME Archive ToDo:Check if <namePart> -->
                    <xsl:when test="matches(mods:name[@type='corporate']/mods:namePart, '^African\s?Methodist\s?Episcopal\s?Church', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Payne Seminary/AME Archive</xsl:text>                          
                            </subfield>
                        	<subfield code="2">
                        		<xsl:text>LOK</xsl:text>
                        	</subfield>
                        </datafield>
                        <datafield tag="935" ind1=" " ind2=" ">
                        	<subfield code="a">
                        		<xsl:text>PRTC</xsl:text>
                        	</subfield>
                        	<subfield code="a">
                                <xsl:text>psam</xsl:text>
                            </subfield>
                            <subfield code="2">
                                <xsl:text>LOK</xsl:text>
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
                        	<subfield code="2">
                        		<xsl:text>LOK</xsl:text>
                        	</subfield>
                        </datafield>
                        <datafield tag="935" ind1=" " ind2=" ">
                        	<subfield code="a">
                        		<xsl:text>PRTC</xsl:text>
                        	</subfield>
                        	<subfield code="a">
                                <xsl:text>resm</xsl:text>
                            </subfield>
                            <subfield code="2">
                                <xsl:text>LOK</xsl:text>
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- Robert Hamill Nassau Manuscript Collection -->
                    <xsl:when test="matches(mods:note, '^Robert\s?Hamill\s?Nassau\s?Manuscript', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#Robert Hamill Nassau Manuscript Collection</xsl:text>                          
                            </subfield>
                        	<subfield code="2">
                        		<xsl:text>LOK</xsl:text>
                        	</subfield>
                        </datafield>
                        <datafield tag="935" ind1=" " ind2=" ">
                        	<subfield code="a">
                        		<xsl:text>PRTC</xsl:text>
                        	</subfield>
                        	<subfield code="a">
                                <xsl:text>rhnm</xsl:text>
                            </subfield>
                            <subfield code="2">
                                <xsl:text>LOK</xsl:text>
                            </subfield>
                        </datafield>
                    </xsl:when>
                    <!-- The Scott Family  Collection -->
                    <xsl:when test="matches(mods:note, '^the\s?Scott\s?Family', 'i')">
                        <datafield tag="866" ind1=" " ind2=" ">
                            <subfield code="a">
                                <xsl:text>SPQUE#Theological Commons Princeton#SPSAM#The Scott Family Collection</xsl:text>                          
                            </subfield>
                        	<subfield code="2">
                        		<xsl:text>LOK</xsl:text>
                        	</subfield>
                        </datafield>
                        <datafield tag="935" ind1=" " ind2=" ">
                        	<subfield code="a">
                        		<xsl:text>PRTC</xsl:text>
                        	</subfield>
                        	<subfield code="a">
                                <xsl:text>sfco</xsl:text>
                            </subfield>
                            <subfield code="2">
                                <xsl:text>LOK</xsl:text>
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
                        	<subfield code="2">
                        		<xsl:text>LOK</xsl:text>
                        	</subfield>
                        </datafield>
                        <datafield tag="935" ind1=" " ind2=" ">
                        	<subfield code="a">
                        		<xsl:text>PRTC</xsl:text>
                        	</subfield>
                        	<subfield code="a">
                                <xsl:text>tftc</xsl:text>
                            </subfield>
                            <subfield code="2">
                                <xsl:text>LOK</xsl:text>
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
                        	<subfield code="2">
                        		<xsl:text>LOK</xsl:text>
                        	</subfield>
                        </datafield>
                        <datafield tag="935" ind1=" " ind2=" ">
                        	<subfield code="a">
                        		<xsl:text>PRTC</xsl:text>
                        	</subfield>
                        	<subfield code="a">
                                <xsl:text>wemi</xsl:text>
                            </subfield>
                            <subfield code="2">
                                <xsl:text>LOK</xsl:text>
                            </subfield>
                        </datafield>
                    </xsl:when>
                	<xsl:otherwise>
                		<datafield tag="935" ind1=" " ind2=" ">
                			<subfield code="a">PRTC</subfield>
                			<subfield code="2">LOK</subfield>
                		</datafield>
                		<datafield tag="866" ind1=" " ind2=" ">
                			<subfield code="a">
                				<xsl:text>SPQUE#Theological Commons Princeton</xsl:text>                          
                			</subfield>
                			<subfield code="2">
                				<xsl:text>LOK</xsl:text>
                			</subfield>
                		</datafield>
                	</xsl:otherwise>
                </xsl:choose>
			</record>
		</collection>
	</xsl:template>

    <xsl:template match="mods:location">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="*"/>

<!-- Title Info elements -->
	<xsl:template match="mods:titleInfo[not(ancestor-or-self::mods:subject)][not(@type)][1]">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">245</xsl:with-param>
			<xsl:with-param name="ind1">1</xsl:with-param>
			<xsl:with-param name="ind2" select="string-length(mods:nonSort)"/>
			<xsl:with-param name="subfields">
				<xsl:call-template name="titleInfo"/>
				<!-- 1/04 fix -->
				<xsl:call-template name="stmtOfResponsibility"/>
				<xsl:call-template name="form"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="mods:titleInfo[@type='abbreviated']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">210</xsl:with-param>
			<xsl:with-param name="ind1">1</xsl:with-param>
			<xsl:with-param name="subfields">
				<xsl:call-template name="titleInfo"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="mods:titleInfo[@type='translated']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">242</xsl:with-param>
			<xsl:with-param name="ind1">1</xsl:with-param>
			<xsl:with-param name="ind2" select="string-length(mods:nonSort)"/>
			<xsl:with-param name="subfields">
				<xsl:call-template name="titleInfo"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="mods:titleInfo[@type='alternative']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">246</xsl:with-param>
			<xsl:with-param name="ind1">3</xsl:with-param>
			<xsl:with-param name="subfields">
				<xsl:call-template name="titleInfo"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="mods:titleInfo[@type='uniform'][1]">
		<xsl:choose>
			<!-- v3 role -->
			<xsl:when test="../mods:name/mods:role/mods:roleTerm[@type='text']='creator' or mods:name/mods:role/mods:roleTerm[@type='code']='cre'">
				<xsl:call-template name="datafield">
					<xsl:with-param name="tag">240</xsl:with-param>
					<xsl:with-param name="ind1">1</xsl:with-param>
					<xsl:with-param name="ind2" select="string-length(mods:nonSort)"/>
					<xsl:with-param name="subfields">
						<xsl:call-template name="titleInfo"/>
					</xsl:with-param>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="datafield">
					<xsl:with-param name="tag">130</xsl:with-param>
					<xsl:with-param name="ind1" select="string-length(mods:nonSort)"/>
					<xsl:with-param name="subfields">
						<xsl:call-template name="titleInfo"/>
					</xsl:with-param>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- 1/04 fix: 2nd uniform title to 730 -->
	<xsl:template match="mods:titleInfo[@type='uniform'][position()>1]">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">730</xsl:with-param>
			<xsl:with-param name="ind1" select="string-length(mods:nonSort)"/>
			<xsl:with-param name="subfields">
				<xsl:call-template name="titleInfo"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<!-- 1/04 fix -->

	<xsl:template match="mods:titleInfo[not(ancestor-or-self::mods:subject)][not(@type)][position()>1]">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">246</xsl:with-param>
			<xsl:with-param name="ind1">3</xsl:with-param>
			<xsl:with-param name="subfields">
				<xsl:call-template name="titleInfo"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

<!-- Name elements -->
	<!-- v3 role-->
	<!-- 3.03 -->

	<xsl:template match="mods:name[@type='personal'][mods:role/mods:roleTerm[@type='text']='creator' or mods:role/mods:roleTerm[@type='code']='cre']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">100</xsl:with-param>
			<xsl:with-param name="ind1">1</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code="a">
					<!-- 2.02 -->
					<xsl:for-each select="mods:namePart[not(@type = 'termsOfAddress') and not(@type='date') or mods:namePart]">
						<xsl:choose>
							<xsl:when test="@type='family' and following-sibling::mods:namePart[@type='given']">
								<xsl:value-of select="concat(.,', ')"/>
							</xsl:when>
							<xsl:otherwise><xsl:value-of select="."/><xsl:if test="following-sibling::*"><xsl:text> </xsl:text></xsl:if></xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</subfield>
				<!-- v3 termsOfAddress -->
				<xsl:for-each select="mods:namePart[@type='termsOfAddress']">
					<subfield code="c">
						<xsl:value-of select="."/>
					</subfield>
				</xsl:for-each>
				<xsl:for-each select="mods:namePart[@type='date']">
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
				<xsl:for-each select="mods:role/mods:roleTerm[@type='code']">
					<subfield code="4">
						<xsl:value-of select="."/>
					</subfield>
				</xsl:for-each>
				<xsl:for-each select="mods:affiliation">
					<subfield code="u">
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
	<xsl:template match="mods:name[@type='corporate'][mods:role/mods:roleTerm[@type='text']='creator' or mods:role/mods:roleTerm[@type='code']='cre']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">110</xsl:with-param>
			<xsl:with-param name="ind1">2</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code="a">
					<xsl:value-of select="mods:namePart[1]"/>
				</subfield>
				<xsl:for-each select="mods:namePart[position()>1]">
					<subfield code="b">
						<xsl:value-of select="."/>
					</subfield>
				</xsl:for-each>
				<!-- v3 role -->
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
	<xsl:template match="mods:name[@type='conference'][mods:role/mods:roleTerm[@type='text']='creator' or mods:role/mods:roleTerm[@type='code']='cre']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">111</xsl:with-param>
			<xsl:with-param name="ind1">2</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code="a">
					<xsl:value-of select="mods:namePart[1]"/>
				</subfield>
				<!-- v3 role -->
				<xsl:for-each select="mods:role/mods:roleTerm[@type='code']">
					<subfield code="4">
						<xsl:value-of select="."/>
					</subfield>
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
				<xsl:for-each select="mods:role/mods:roleTerm[@type='code']">
					<subfield code="4">
						<xsl:value-of select="."/>
					</subfield>
				</xsl:for-each>
				<xsl:for-each select="mods:affiliation">
					<subfield code="u">
						<xsl:value-of select="."/>
					</subfield>
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
				<subfield code="a">
					<xsl:value-of select="mods:namePart[1]"/>
				</subfield>
				<!-- v3 role -->
				<xsl:for-each select="mods:role/mods:roleTerm[@type='code']">
					<subfield code="4">
						<xsl:value-of select="."/>
					</subfield>
				</xsl:for-each>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="mods:name[not(@type)]">
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
	<xsl:template match="mods:name[not(@type)]">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">100</xsl:with-param>
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
	<!-- Genre elements -->
	<!-- 2.01 -->
	<xsl:template match="mods:genre[@authority!='marcgt' or not(@authority)]">
		<xsl:variable name="dfv">
			<xsl:choose>
				<xsl:when test="@authority = 'content' and @type='musical composition'">047</xsl:when>
				<xsl:when test="@authority = 'content'">336</xsl:when>
				<xsl:otherwise>655</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="parent::mods:subject">
				<xsl:choose>
					<xsl:when test="following-sibling::* or preceding-sibling::*">
						<subfield code="v">
							<xsl:value-of select="."/>
						</subfield>
					</xsl:when>
					<xsl:otherwise>
						<xsl:call-template name="datafield">
							<xsl:with-param name="tag">655</xsl:with-param>
							<xsl:with-param name="ind2">7</xsl:with-param>
							<xsl:with-param name="subfields">
								<subfield code='a'>
									<xsl:value-of select="."/>
								</subfield>
								<xsl:for-each select="@authority">
									<subfield code='2'>
										<xsl:value-of select="."/>
									</subfield>
								</xsl:for-each>
							</xsl:with-param>
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="datafield">
					<xsl:with-param name="tag"><xsl:value-of select="$dfv"/></xsl:with-param>
					<!-- 3.00  -->
					<xsl:with-param name="ind2">
						<xsl:choose>
							<xsl:when test="@type='musical composition' and @authority='marcmuscomp'">#</xsl:when>
							<xsl:otherwise>7</xsl:otherwise>
						</xsl:choose>
					</xsl:with-param>
					<xsl:with-param name="subfields">
						<subfield code='a'>
							<xsl:value-of select="."/>
						</subfield>
						<xsl:for-each select="@authority">
							<subfield code='2'>
								<xsl:value-of select="."/>
							</subfield>
						</xsl:for-each>
					</xsl:with-param>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- ubtue:manual additions for physicalDescription-->
	<xsl:template match="mods:physicalDescription/mods:form[@authority='local']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">650</xsl:with-param>
			<xsl:with-param name="ind2">4</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code='a'>
					<xsl:text>|f|</xsl:text><xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	
	<!-- 650 MARC from MODS data [besser als Lokales Schlagwort im Exemplardaten?]-->
	<xsl:template match="//*[local-name()='physicalDescription']/*[local-name()='form'][@authority='local']">
		<datafield tag="650" ind1=" " ind2="4">
			<subfield code="a">
				<xsl:value-of select="concat('|f|', //*[local-name()='physicalDescription']/*[local-name()='form'][@authority='local']/text())"/>
			</subfield>
			<subfield code="2">
				<xsl:text>LOK</xsl:text>
			</subfield>
		</datafield>
	</xsl:template>
	
	<!-- ubtue: remove linebreak-->
	<xsl:template match="*/text()[normalize-space()]">
		<xsl:value-of select="normalize-space()"/>
	</xsl:template>
	<xsl:template match="*/text()[not(normalize-space())]" />
	
    <!-- ubtue: tag 300
	<xsl:template match="mods:extension">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">300</xsl:with-param>
			<xsl:with-param name="ind1"></xsl:with-param>
			<xsl:with-param name="ind2"></xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code='a'>
					<xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>	
		</xsl:call-template>
	</xsl:template>	-->
	

<!-- Origin Info elements -->
	<xsl:template match="mods:originInfo">
		<!-- v3.4 Added for 264 ind2 = 0, 1, 2, 3-->
		<!-- v3 place, and fixed "mods:placeCode (v1?) -->
		<xsl:for-each select="mods:place/mods:placeTerm[@type='code'][@authority='iso3166']">
			<xsl:call-template name="datafield">
				<xsl:with-param name="tag">044</xsl:with-param>
				<xsl:with-param name="subfields">
					<subfield code='c'>
						<xsl:value-of select="."/>
					</subfield>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:for-each>
	    <!-- v3.4 --> 						
	    <xsl:if test="mods:dateCaptured[@encoding='iso8601']|mods:dateCoptured">
			<xsl:call-template name="datafield">
				<xsl:with-param name="tag">033</xsl:with-param>
				<xsl:with-param name="ind1">
					<xsl:choose>
						<xsl:when test="mods:dateCaptured[@point='start']|mods:dateCaptured[@point='end']">2</xsl:when>
					    <xsl:otherwise>0</xsl:otherwise>
					</xsl:choose>
				</xsl:with-param>
				<xsl:with-param name="ind2">0</xsl:with-param>
				<xsl:with-param name="subfields">
					<xsl:for-each select="mods:dateCaptured">
						<subfield code='a'>
							<xsl:value-of select="."/>
						</subfield>
					</xsl:for-each>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
	    <!-- ubtue -->
	    <xsl:if test="mods:dateCaptured">
	        <xsl:call-template name="datafield">
	            <xsl:with-param name="tag">264</xsl:with-param>
	            <xsl:with-param name="ind1">3</xsl:with-param>
	            <xsl:with-param name="ind2">1</xsl:with-param>
	            <xsl:with-param name="subfields">
	                <xsl:for-each select="mods:dateCaptured">
	                    <subfield code='c'>
	                        <xsl:value-of select="."/>
	                    </subfield>
	                </xsl:for-each>
	            </xsl:with-param>
	        </xsl:call-template>
	    </xsl:if>
		<!-- v3 dates -->
		<xsl:if test="mods:dateModified|mods:dateCreated|mods:dateValid">
			<xsl:call-template name="datafield">
				<xsl:with-param name="tag">046</xsl:with-param>
				<xsl:with-param name="subfields">
					<xsl:for-each select="mods:dateModified">
						<subfield code='j'>
							<xsl:value-of select="."/>
						</subfield>
					</xsl:for-each>
					<xsl:for-each select="mods:dateCreated[@point='start']|mods:dateCreated[not(@point)]">
						<subfield code='k'>
							<xsl:value-of select="."/>
						</subfield>
					</xsl:for-each>
					<xsl:for-each select="mods:dateCreated[@point='end']">
						<subfield code='l'>
							<xsl:value-of select="."/>
						</subfield>
					</xsl:for-each>
					<xsl:for-each select="mods:dateValid[@point='start']|mods:dateValid[not(@point)]">
						<subfield code='m'>
							<xsl:value-of select="."/>
						</subfield>
					</xsl:for-each>
					<xsl:for-each select="mods:dateValid[@point='end']">
						<subfield code='n'>
							<xsl:value-of select="."/>
						</subfield>
					</xsl:for-each>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
		<xsl:for-each select="mods:edition">
			<xsl:call-template name="datafield">
				<xsl:with-param name="tag">250</xsl:with-param>
				<xsl:with-param name="subfields">
					<subfield code='a'>
						<xsl:value-of select="."/>
					</subfield>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:for-each>
		<xsl:for-each select="mods:frequency">
			<xsl:call-template name="datafield">
				<xsl:with-param name="tag">310</xsl:with-param>
				<xsl:with-param name="subfields">
					<subfield code='a'>
						<xsl:value-of select="."/>
					</subfield>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:for-each>
		<xsl:for-each select="mods:issuance">
			<xsl:call-template name="datafield">
				<xsl:with-param name="tag">250</xsl:with-param>
				<xsl:with-param name="subfields">
					<subfield code='a'>
						<xsl:value-of select="."/>
					</subfield>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:for-each>
		<xsl:if test="mods:place/mods:placeTerm[@type='text'] or mods:publisher or mods:dateIssued or mods:dateCreated">
			<xsl:call-template name="datafield">
				<!-- 3.00  -->
				<xsl:with-param name="tag">
					<xsl:choose>
						<xsl:when test="@eventType='production' or @eventType='publication' or
							@eventType='distribution' or @eventType='manufacture' or
							@displayLabel='producer' or @displayLabel='publisher'
							or @displayLabel='manufacturer' or @displayLabel='distributor'">264</xsl:when>
						<xsl:otherwise>260</xsl:otherwise>
					</xsl:choose>
				</xsl:with-param>
				<!-- 3.00  -->
				<xsl:with-param name="ind2">
					<xsl:choose>
						<xsl:when test="@displayLabel='producer' or @eventType='production'">0</xsl:when>
						<xsl:when test="@displayLabel='publisher' or @eventType='publication'">1</xsl:when>
						<xsl:when test="@displayLabel='manufacturer' or @eventType='distribution'">2</xsl:when>
						<xsl:when test="@displayLabel='distributor' or @eventType='manufacture'">3</xsl:when>
						<xsl:otherwise><xsl:text> </xsl:text></xsl:otherwise>
					</xsl:choose>
				</xsl:with-param>
				<xsl:with-param name="subfields">
					<!-- v3 place; changed to text  -->
					<xsl:for-each select="mods:place/mods:placeTerm[@type='text']">
						<subfield code='a'>
							<xsl:value-of select="."/>
						</subfield>
					</xsl:for-each>
					<xsl:for-each select="mods:publisher">
						<subfield code='b'>
							<xsl:value-of select="."/>
						</subfield>
					</xsl:for-each>
					<xsl:for-each select="mods:dateIssued[@point='start'] | mods:dateIssued[not(@point)]">
						<subfield code='c'>
							<xsl:value-of select="."/>
							<!-- v3.4 generate question mark for dateIssued with qualifier="questionable" -->
							<xsl:if test="@qualifier='questionable'">?</xsl:if>
							<!-- v3.4 Generate a hyphen before end date -->
							<xsl:if test="mods:dateIssued[@point='end']">
								- <xsl:value-of select="../mods:dateIssued[@point='end']"/>
							</xsl:if>
						</subfield>
					</xsl:for-each>
					<xsl:for-each select="mods:dateCreated">
						<subfield code='g'>
							<xsl:value-of select="."/>
						</subfield>
					</xsl:for-each>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>

<!-- Language -->
	<!-- v3.4 language with objectPart-->
	<xsl:template match="mods:language/mods:languageTerm[@objectPart]">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">041</xsl:with-param>
			<xsl:with-param name="ind1">0</xsl:with-param>
			<xsl:with-param name="subfields">
				<xsl:choose>
					<xsl:when test="@objectPart='text/sound track'">
						<subfield code='a'>
							<xsl:value-of select="."/>
						</subfield>
					</xsl:when>
					<xsl:when test="@objectPart='summary or abstract' or @objectPart='summary' or @objectPart='abstract'">
						<subfield code='b'>
							<xsl:value-of select="."/>
						</subfield>
					</xsl:when>
					<xsl:when test="@objectPart='sung or spoken text'">
						<subfield code='d'>
							<xsl:value-of select="."/>
						</subfield>
					</xsl:when>
					<xsl:when test="@objectPart='librettos' or @objectPart='libretto'">
						<subfield code='e'>
							<xsl:value-of select="."/>
						</subfield>
					</xsl:when>
					<xsl:when test="@objectPart='table of contents'">
						<subfield code='f'>
							<xsl:value-of select="."/>
						</subfield>
					</xsl:when>
					<xsl:when test="@objectPart='accompanying material other than librettos' or @objectPart='accompanying material'">
						<subfield code='g'>
							<xsl:value-of select="."/>
						</subfield>
					</xsl:when>
					<xsl:when test="@objectPart='original and/or intermediate translations of text' or @objectPart='translation'">
						<subfield code='h'>
							<xsl:value-of select="."/>
						</subfield>
					</xsl:when>
					<xsl:when test="@objectPart='subtitles or captions' or @objectPart='subtitle or caption'">
						<subfield code='j'>
							<xsl:value-of select="."/>
						</subfield>
					</xsl:when>
					<xsl:otherwise>
						<subfield code='a'>
							<xsl:value-of select="."/>
						</subfield>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<!-- v3 language -->
	<xsl:template match="mods:language/mods:languageTerm[@authority='iso639-2b']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">041</xsl:with-param>
			<xsl:with-param name="ind1">0</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code='a'>
					<xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<!-- v3 language -->
	<xsl:template match="mods:language/mods:languageTerm[@authority='rfc3066']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">041</xsl:with-param>
			<xsl:with-param name="ind1">0</xsl:with-param>
			<xsl:with-param name="ind2">7</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code='a'>
					<xsl:value-of select="."/>
				</subfield>
				<subfield code='2'>rfc3066</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<!-- v3.4 language with scriptTerm -->
	<xsl:template match="mods:language/mods:languageTerm[@authority='rfc3066']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">546</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code='b'>
					<xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

<!-- Physical Description -->
	<xsl:template match="mods:physicalDescription">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="mods:extent">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">300</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code='a'>
					<xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<!-- v3.4 Added for 337 and 338 mods:form-->
	<xsl:template match="mods:form[@type='media']|mods:form[@type='carrier']|mods:form[@type='material']|mods:form[@type='technique']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">
				<xsl:choose>
					<xsl:when test="@type='media'">337</xsl:when>
					<xsl:when test="@type='carrier'">338</xsl:when>
					<xsl:when test="@type='material'">340</xsl:when>
					<xsl:when test="@type='technique'">340</xsl:when>
				</xsl:choose>
			</xsl:with-param>
			<xsl:with-param name="subfields">
				<xsl:if test="not(@type='technique')">
					<subfield code='a'>
						<xsl:value-of select="."/>
					</subfield>
				</xsl:if>
				<xsl:if test="@type='technique'">
					<subfield code='d'>
						<xsl:value-of select="."/>
					</subfield>
				</xsl:if>
				<xsl:if test="@authority">
					<subfield code='2'>
						<xsl:value-of select="@authority"/>
					</subfield>
				</xsl:if>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

<!-- Abstract -->
	<xsl:template match="mods:abstract">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">520</xsl:with-param>
			<xsl:with-param name="ind1">
			<!-- v3.4 added values for ind1 based on displayLabel -->
				<xsl:choose>
					<xsl:when test="@displayLabel='Subject'">0</xsl:when>
					<xsl:when test="@displayLabel='Review'">1</xsl:when>
					<xsl:when test="@displayLabel='Scope and content'">2</xsl:when>
					<xsl:when test="@displayLabel='Abstract'">2</xsl:when>
					<xsl:when test="@displayLabel='Content advice'">4</xsl:when>
					<xsl:otherwise><xsl:text> </xsl:text></xsl:otherwise>
				</xsl:choose>
			</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code="a">
					<xsl:value-of select="."/>
				</subfield>
				<xsl:for-each select="@xlink:href">
					<subfield code="u">
						<xsl:value-of select="."/>
					</subfield>
				</xsl:for-each>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

<!-- Table of Contents -->
	<xsl:template match="mods:tableOfContents">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">505</xsl:with-param>
			<xsl:with-param name="ind1">
				<!-- v3.4 added values for ind1 based on displayLabel -->
				<xsl:choose>
					<xsl:when test="@displayLabel='Contents'">0</xsl:when>
					<xsl:when test="@displayLabel='Incomplete contents'">1</xsl:when>
					<xsl:when test="@displayLabel='Partial contents'">2</xsl:when>
					<xsl:otherwise>0</xsl:otherwise>
				</xsl:choose>
			</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code="a">
					<xsl:value-of select="."/>
				</subfield>
				<xsl:for-each select="@xlink:href">
					<subfield code="u">
						<xsl:value-of select="."/>
					</subfield>
				</xsl:for-each>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

<!-- Target Audience -->
	<!-- 1/04 fix -->
<!--	<xsl:template match="mods:targetAudience">
		<xsl:apply-templates/>
	</xsl:template>-->

	<!--<xsl:template match="mods:targetAudience/mods:otherValue"> -->
	<xsl:template match="mods:targetAudience[not(@authority)] | mods:targetAudience[@authority!='marctarget']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">521</xsl:with-param>
			<xsl:with-param name="ind1">
				<!-- v3.4 added values for ind1 based on displayLabel -->
				<xsl:choose>
					<xsl:when test="@displayLabel='Reading grade level'">0</xsl:when>
					<xsl:when test="@displayLabel='Interest age level'">1</xsl:when>
					<xsl:when test="@displayLabel='Interest grade level'">2</xsl:when>
					<xsl:when test="@displayLabel='Special audience characteristics'">3</xsl:when>
					<xsl:when test="@displayLabel='Motivation or interest level'">3</xsl:when>
					<xsl:otherwise><xsl:text> </xsl:text></xsl:otherwise>
				</xsl:choose>
			</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code='a'>
					<xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

<!-- Note -->
	<!-- 1/04 fix -->
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
					<subfield code='u'>
						<xsl:value-of select="."/>
					</subfield>
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

	<!-- 1/04 fix -->
	<!--<xsl:template match="mods:note[@type='statement of responsibility']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">245</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code='c'>
					<xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
-->
	<xsl:template match="mods:accessCondition">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">
			<xsl:choose>
				<xsl:when test="@type='restrictionOnAccess'">506</xsl:when>
				<xsl:when test="@type='useAndReproduction'">540</xsl:when>
				<xsl:when test="@type='use and reproduction'">540</xsl:when>
			</xsl:choose>
			</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code='a'>
					<xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<!-- 1/04 fix -->
	<xsl:template name="controlRecordInfo">
	<!--<xsl:template match="mods:recordInfo">-->
		<xsl:for-each select="mods:identifier">
			<controlfield tag="001"><xsl:value-of select="."/></controlfield>
			<xsl:for-each select="@source">
				<controlfield tag="003"><xsl:value-of select="."/></controlfield>
			</xsl:for-each>
		</xsl:for-each>
		<controlfield tag="003">DE-Tue135</controlfield>
		<xsl:for-each select="mods:recordInfo/mods:recordChangeDate[@encoding='iso8601']">
			<controlfield tag="005"><xsl:value-of select="."/></controlfield>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="source">
		<xsl:for-each select="mods:recordInfo/mods:recordContentSource[@authority='marcorg']">
			<xsl:call-template name="datafield">
				<xsl:with-param name="tag">040</xsl:with-param>
				<xsl:with-param name="subfields">
					<subfield code="a">
						<xsl:value-of select="."/>
					</subfield>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>

	<!-- v3 authority -->

	<xsl:template match="mods:subject">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="mods:subject[local-name(*[1])='topic']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">650</xsl:with-param>
			<xsl:with-param name="ind1">1</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code="a">
					<xsl:value-of select="*[1]"/>
				</subfield>
				<xsl:apply-templates select="*[position()>1]"/>
			</xsl:with-param>
		</xsl:call-template>
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

	<xsl:template match="mods:subject[local-name(*[1])='name']">
		<xsl:for-each select="*[1]">
			<xsl:choose>
				<xsl:when test="@type='personal'">
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
				<xsl:when test="@type='corporate'">
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
				<xsl:when test="@type='conference'">
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

	<xsl:template match="mods:subject[local-name(*[1])='geographic']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">651</xsl:with-param>
			<xsl:with-param name="ind2"><xsl:call-template name="authorityInd"/></xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code="a">
					<xsl:value-of select="*[1]"/>
				</subfield>
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

	<!-- v3 geographicCode -->
	<xsl:template match="mods:subject/mods:geographicCode[@authority]">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">043</xsl:with-param>
			<xsl:with-param name="subfields">
				<xsl:for-each select="self::mods:geographicCode[@authority='marcgac']">
					<subfield code='a'>
						<xsl:value-of select="."/>
					</subfield>
				</xsl:for-each>
				<xsl:for-each select="self::mods:geographicCode[@authority='iso3166']">
					<subfield code='c'>
						<xsl:value-of select="."/>
					</subfield>
				</xsl:for-each>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<!-- 1/04 fix was 630 -->
	<!-- 3.02  -->
	<xsl:template match="mods:subject/mods:hierarchicalGeographic">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">662</xsl:with-param>
			<xsl:with-param name="subfields">
				<xsl:for-each select="mods:country | mods:region | mods:territory | mods:island">
					<subfield code="a">
						<xsl:value-of select="."/>
					</subfield>
				</xsl:for-each>
				<xsl:for-each select="mods:state">
					<subfield code="b">
						<xsl:value-of select="."/>
					</subfield>
				</xsl:for-each>
				<xsl:for-each select="mods:county">
					<subfield code="c">
						<xsl:value-of select="."/>
					</subfield>
				</xsl:for-each>
				<xsl:for-each select="mods:city">
					<subfield code="d">
						<xsl:value-of select="."/>
					</subfield>
				</xsl:for-each>
				<xsl:for-each select="mods:citySection">
					<subfield code="e">
						<xsl:value-of select="."/>
					</subfield>
				</xsl:for-each>
				<xsl:for-each select="mods:extraterrestrialArea">
					<subfield code="h">
						<xsl:value-of select="."/>
					</subfield>
				</xsl:for-each>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="mods:subject/mods:cartographics">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">255</xsl:with-param>
			<xsl:with-param name="subfields">
				<xsl:for-each select="mods:coordinates">
					<subfield code="c">
						<xsl:value-of select="."/>
					</subfield>
				</xsl:for-each>
				<xsl:for-each select="mods:scale">
					<subfield code="a">
						<xsl:value-of select="."/>
					</subfield>
				</xsl:for-each>
				<xsl:for-each select="mods:projection">
					<subfield code="b">
						<xsl:value-of select="."/>
					</subfield>
				</xsl:for-each>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="mods:subject/mods:occupation">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">656</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code="a">
					<xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
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
			<xsl:value-of select="."/>
		</subfield>
	</xsl:template>
	<!-- 2.01
	<xsl:template match="mods:subject/mods:genre">
		<subfield code="v">
			<xsl:value-of select="."/>
		</subfield>
	</xsl:template>
	-->

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

	<xsl:template name="stmtOfResponsibility">
		<xsl:for-each select="following-sibling::mods:note[@type='statement of responsibility']">
			<subfield code='c'>
				<xsl:value-of select="."/>
			</subfield>
		</xsl:for-each>
	</xsl:template>

<!-- Classification -->

	<!--<xsl:template match="mods:classification[@authority='lcc']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">050</xsl:with-param>
			<xsl:with-param name="ind2">
				<xsl:choose>
				<xsl:when test="../mods:recordInfo/mods:recordContentSource='DLC' or ../mods:recordInfo/mods:recordContentSource='Library of Congress'">0</xsl:when>
				<xsl:otherwise>2</xsl:otherwise>
				</xsl:choose>
			</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code="a">
					<xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
-->

	<xsl:template match="mods:classification[@authority='ddc']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">082</xsl:with-param>
			<xsl:with-param name="ind1">0</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code="a">
					<xsl:value-of select="."/>
				</subfield>
				<xsl:for-each select="@edition">
					<subfield code="2">
						<xsl:value-of select="."/>
					</subfield>
				</xsl:for-each>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="mods:classification[@authority='udc']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">080</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code="a">
					<xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="mods:classification[@authority='nlm']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">060</xsl:with-param>
			<xsl:with-param name="ind2">4</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code="a">
					<xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="mods:classification[@authority='sudocs']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">086</xsl:with-param>
			<xsl:with-param name="ind1">0</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code="a">
					<xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="mods:classification[@authority='candocs']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">086</xsl:with-param>
			<xsl:with-param name="ind1">1</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code="a">
					<xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<!-- v3.4 -->
	<xsl:template match="mods:classification[@authority='content']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">084</xsl:with-param>
			<xsl:with-param name="ind1">1</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code="a">
					<xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="lcClassification">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">050</xsl:with-param>
			<xsl:with-param name="ind2">
				<xsl:choose>
					<xsl:when test="../mods:recordInfo/mods:recordContentSource='DLC' or ../mods:recordInfo/mods:recordContentSource='Library of Congress'">0</xsl:when>
					<xsl:otherwise>2</xsl:otherwise>
				</xsl:choose>
			</xsl:with-param>
			<xsl:with-param name="subfields">
				<xsl:for-each select="mods:classification[@authority='lcc']">
					<subfield code="a">
						<xsl:value-of select="."/>
					</subfield>
				</xsl:for-each>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

<!-- Identifiers -->
	<!-- v3.4 updated doi subfields and datafield mapping -->
	<xsl:template match="mods:identifier[@type='doi'] | mods:identifier[@type='hdl'] ">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">024</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code="a">
					<xsl:value-of select="."/>
				</subfield>
				<subfield code="2">
					<xsl:value-of select="@type"/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="mods:identifier[@type='isbn']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">020</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield>
					<!-- v3.4 updated code to handle invalid isbn -->
					<xsl:attribute name="code">
						<xsl:choose>
							<xsl:when test="@invalid='yes'">z</xsl:when>
							<xsl:otherwise>a</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
					<xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="mods:identifier[@type='isrc']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">024</xsl:with-param>
			<xsl:with-param name="ind1">0</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield>
					<!-- v3.4 updated code to handle invalid isbn -->
					<xsl:attribute name="code">
						<xsl:choose>
							<xsl:when test="@invalid='yes'">z</xsl:when>
							<xsl:otherwise>a</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
					<xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="mods:identifier[@type='ismn']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">024</xsl:with-param>
			<xsl:with-param name="ind1">2</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield>
					<!-- v3.4 updated code to handle invalid isbn -->
					<xsl:attribute name="code">
						<xsl:choose>
							<xsl:when test="@invalid='yes'">z</xsl:when>
							<xsl:otherwise>a</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
					<xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="mods:identifier[@type='issn'] | mods:identifier[@type='issn-l'] ">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">022</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield>
					<!-- v3.4 updated code to handle invalid isbn -->
					<xsl:attribute name="code">
						<xsl:choose>
							<xsl:when test="@invalid='yes'">z</xsl:when>
							<xsl:otherwise>a</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
					<xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="mods:identifier[@type='issue number']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">028</xsl:with-param>
			<xsl:with-param name="ind1">0</xsl:with-param>
			<xsl:with-param name="ind2">0</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code="a">
					<xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="mods:identifier[@type='lccn']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">010</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield>
					<!-- v3.4 updated code to handle invalid isbn -->
					<xsl:attribute name="code">
						<xsl:choose>
							<xsl:when test="@invalid='yes'">z</xsl:when>
							<xsl:otherwise>a</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
					<xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="mods:identifier[@type='matrix number']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">028</xsl:with-param>
			<xsl:with-param name="ind1">1</xsl:with-param>
			<xsl:with-param name="ind2">0</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code="a">
					<xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="mods:identifier[@type='music publisher']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">028</xsl:with-param>
			<xsl:with-param name="ind1">3</xsl:with-param>
			<xsl:with-param name="ind2">0</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code="a">
					<xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="mods:identifier[@type='music plate']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">028</xsl:with-param>
			<xsl:with-param name="ind1">2</xsl:with-param>
			<xsl:with-param name="ind2">0</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code="a">
					<xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="mods:identifier[@type='sici']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">024</xsl:with-param>
			<xsl:with-param name="ind1">4</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield>
					<!-- v3.4 updated code to handle invalid isbn -->
					<xsl:attribute name="code">
						<xsl:choose>
							<xsl:when test="@invalid='yes'">z</xsl:when>
							<xsl:otherwise>a</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
					<xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<!-- v3.4 -->
	<xsl:template match="mods:identifier[@type='stocknumber']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">037</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code="a">
					<xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="mods:identifier[@type='uri']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">856</xsl:with-param>
			<xsl:with-param name="ind2"><xsl:text> </xsl:text></xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code="u">
					<xsl:value-of select="."/>
				</subfield>
				<xsl:call-template name="mediaType"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<!--v3 location/url -->
	<!-- 2.01 -->
	<xsl:template match="mods:location/mods:url">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">856</xsl:with-param>
			<xsl:with-param name="ind1"><xsl:text>4</xsl:text></xsl:with-param>
			<xsl:with-param name="ind2"><xsl:text>0</xsl:text></xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code="u">
					<xsl:value-of select="."/>
				</subfield>
				<subfield code="z">
					<xsl:text>LF</xsl:text>
				</subfield>
				<!-- v3 displayLabel -->
				<xsl:for-each select="@displayLabel">
					<subfield code="3">
						<xsl:value-of select="."/>
					</subfield>
				</xsl:for-each>
				<xsl:for-each select="@dateLastAccessed">
					<subfield code="z">
						<xsl:value-of select="concat('Last accessed: ',.)"/>
					</subfield>
				</xsl:for-each>
			</xsl:with-param>
			</xsl:call-template>
	</xsl:template>
	<xsl:template match="mods:identifier[@type='upc']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">024</xsl:with-param>
			<xsl:with-param name="ind1">1</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield>
					<!-- v3.4 updated code to handle invalid isbn -->
					<xsl:attribute name="code">
						<xsl:choose>
							<xsl:when test="@invalid='yes'">z</xsl:when>
							<xsl:otherwise>a</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
					<xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="mods:identifier[@type='videorecording']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">028</xsl:with-param>
			<xsl:with-param name="ind1">4</xsl:with-param>
			<xsl:with-param name="ind2">0</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code="a">
					<xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
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

	<xsl:template match="mods:relatedItem/mods:identifier[@type='uri']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">856</xsl:with-param>
			<xsl:with-param name="ind2">2</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code="u">
					<xsl:value-of select="."/>
				</subfield>
				<xsl:call-template name="mediaType"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<!-- v3 physicalLocation -->
	<!-- 2.01 -->
	<!-- unescape 852 should be local 852 -->
	<!--<xsl:template match="mods:location/mods:physicalLocation">
			<xsl:call-template name="datafield">
				<xsl:with-param name="tag">852</xsl:with-param>
				<xsl:with-param name="subfields">
					<subfield code="a">
						<xsl:value-of select="."/>
					</subfield>
					<xsl:if test="@xlink">
						<subfield code="u">
							<xsl:value-of select="."/>
						</subfield>
					</xsl:if>-->
					<!-- v3 displayLabel 
					<xsl:for-each select="@displayLabel">
						<subfield code="3">
							<xsl:value-of select="."/>
						</subfield>
					</xsl:for-each>
				</xsl:with-param>
			</xsl:call-template>
	</xsl:template>-->
	<!-- 2.01 -->
<!-- v3.4 add physical location url
	<xsl:template match="mods:location/mods:physicalLocation[@xlink]">
		<xsl:for-each select="mods:physicalLocation">
			<xsl:call-template name="datafield">
				<xsl:with-param name="tag">852</xsl:with-param>
				<xsl:with-param name="subfields">
					<subfield code="u">
						<xsl:value-of select="."/>
					</subfield>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>
	-->
	<!-- v3.4 location url -->
	<!-- 2.01 -->
	<xsl:template match="mods:location/mods:uri">
			<xsl:call-template name="datafield">
				<xsl:with-param name="tag">852</xsl:with-param>
				<xsl:with-param name="subfields">
					<subfield>
						<xsl:choose>
							<xsl:when test="@displayLabel='content'">3</xsl:when>
							<xsl:when test="@dateLastAccessed='content'">z</xsl:when>
							<xsl:when test="@note='contents of subfield'">z</xsl:when>
							<xsl:when test="@access='preview'">3</xsl:when>
							<xsl:when test="@access='raw object'">3</xsl:when>
							<xsl:when test="@access='object in context'">3</xsl:when>
							<xsl:when test="@access='primary display'">z</xsl:when>
						</xsl:choose>
						<xsl:value-of select="."/>
					</subfield>
				</xsl:with-param>
			</xsl:call-template>
	</xsl:template>

	<!-- 1/04 fix -->
	<!--<xsl:template match="mods:internetMediaType">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">856</xsl:with-param>
			<xsl:with-param name="ind2">2</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code="q">
					<xsl:value-of select="."/>
				</subfield>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>	-->

	<xsl:template name="mediaType">
		<xsl:if test="../mods:physicalDescription/mods:internetMediaType">
			<subfield code="q">
				<xsl:value-of select="../mods:physicalDescription/mods:internetMediaType"/>
			</subfield>
		</xsl:if>
	</xsl:template>

	<xsl:template name="form">
		<xsl:if test="../mods:physicalDescription/mods:form[@authority='gmd']">
			<subfield code="h">
				<xsl:value-of select="../mods:physicalDescription/mods:form[@authority='gmd']"/>
			</subfield>
		</xsl:if>
	</xsl:template>

	<!-- v3 isReferencedBy -->
	<xsl:template match="mods:relatedItem[@type='isReferencedBy']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">510</xsl:with-param>
			<xsl:with-param name="subfields">
				<xsl:variable name="noteString">
					<xsl:for-each select="*">
						<xsl:value-of select="concat(.,', ')"/>
					</xsl:for-each>
				</xsl:variable>
				<subfield code="a">
					<xsl:value-of select="substring($noteString, 1,string-length($noteString)-2)"/>
				</subfield>
				<!--<xsl:call-template name="relatedItem76X-78X"/>-->
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="mods:relatedItem[@type='series']">
		<!-- 3.02 -->
		<xsl:choose>
			<xsl:when test="not(mods:name) and mods:titleInfo">
				<xsl:for-each select="mods:titleInfo">
					<xsl:call-template name="datafield">
						<xsl:with-param name="tag">830</xsl:with-param>
						<xsl:with-param name="subfields">
							<xsl:call-template name="titleInfo"/>
						</xsl:with-param>
					</xsl:call-template>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:for-each select="mods:name">
					<xsl:variable name="tagValue">
						<xsl:choose>
							<xsl:when test="@type='personal'">800</xsl:when>
							<xsl:when test="@type='corporate'">810</xsl:when>
							<xsl:when test="@type='conference'">811</xsl:when>
							<xsl:otherwise>830</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:call-template name="datafield">
						<xsl:with-param name="tag" select="$tagValue"/>
						<xsl:with-param name="subfields">
							<subfield code="a">
								<!-- 2.02 -->
								<xsl:value-of select="mods:namePart[1]"/>
							</subfield>
							<xsl:if test="@type='corporate'">
								<xsl:for-each select="mods:namePart[position()>1]">
									<subfield code="b">
										<xsl:value-of select="."/>
									</subfield>
								</xsl:for-each>
							</xsl:if>
							<xsl:if test="@type='personal'">
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
							</xsl:if>
							<!-- v3 role -->
							<xsl:if test="@type!='conference'">
								<xsl:for-each select="mods:role/mods:roleTerm[@type='text']">
									<subfield code="e">
										<xsl:value-of select="."/>
									</subfield>
								</xsl:for-each>
							</xsl:if>
							<xsl:for-each select="mods:role/mods:roleTerm[@type='code']">
								<subfield code="4">
									<xsl:value-of select="."/>
								</subfield>
							</xsl:for-each>
							<xsl:if test="$tagValue != '830' and ../mods:titleInfo">
								<xsl:for-each select="../mods:titleInfo">
									<xsl:for-each select="mods:title">
										<subfield code="t">
											<xsl:value-of select="../mods:nonSort"/><xsl:value-of select="."/><xsl:value-of select="../mods:subTitle"/>
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
								</xsl:for-each>
							</xsl:if>
						</xsl:with-param>
					</xsl:call-template>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>


	<xsl:template match="mods:relatedItem[not(@type)]">
	<!-- v3 was type="related" -->
		<!-- v3.4 updated to handle related items with only location/url child element -->
		<xsl:choose>
			<xsl:when test="mods:location/mods:url and not(mods:titleInfo)">
				<xsl:call-template name="datafield">
					<xsl:with-param name="tag">856</xsl:with-param>
					<xsl:with-param name="ind2">2</xsl:with-param>
					<xsl:with-param name="subfields">
						<subfield code="u">
							<xsl:value-of select="mods:location/mods:url"/>
						</subfield>
					</xsl:with-param>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<!-- 2.01 -->
				<xsl:variable name="content">
					<xsl:call-template name="relatedItem76X-78X"/>
				</xsl:variable>
				<xsl:if test="$content != ''">
					<xsl:call-template name="datafield">
						<xsl:with-param name="tag">787</xsl:with-param>
						<xsl:with-param name="ind1">0</xsl:with-param>
						<xsl:with-param name="subfields">
							<xsl:call-template name="relatedItem76X-78X"/>
						</xsl:with-param>
					</xsl:call-template>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="mods:relatedItem[@type='preceding']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">780</xsl:with-param>
			<xsl:with-param name="ind1">0</xsl:with-param>
			<xsl:with-param name="ind2">0</xsl:with-param>
			<xsl:with-param name="subfields">
				<xsl:call-template name="relatedItem76X-78X"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="mods:relatedItem[@type='succeeding']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">785</xsl:with-param>
			<xsl:with-param name="ind1">0</xsl:with-param>
			<xsl:with-param name="ind2">0</xsl:with-param>
			<xsl:with-param name="subfields">
				<xsl:call-template name="relatedItem76X-78X"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="mods:relatedItem[@type='otherVersion']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">775</xsl:with-param>
			<xsl:with-param name="subfields">
				<xsl:call-template name="relatedItem76X-78X"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="mods:relatedItem[@type='otherFormat']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">776</xsl:with-param>
			<xsl:with-param name="subfields">
				<xsl:call-template name="relatedItem76X-78X"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<!-- 2.01 -->
	<xsl:template match="mods:relatedItem[@type='original']">
		<xsl:variable name="relatedItem76X-78X">
			<xsl:call-template name="relatedItem76X-78X"/>
		</xsl:variable>
		<xsl:if test="$relatedItem76X-78X != ''">
			<xsl:call-template name="datafield">
				<xsl:with-param name="tag">534</xsl:with-param>
				<xsl:with-param name="subfields">
					<xsl:call-template name="relatedItem76X-78X"/>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>

	<xsl:template match="mods:relatedItem[@type='host']">
		<xsl:variable name="dateIssued" select="../mods:originInfo/mods:dateIssued"/>
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">773</xsl:with-param>
			<xsl:with-param name="ind1">0</xsl:with-param>
			<xsl:with-param name="ind2">8</xsl:with-param>
			<xsl:with-param name="subfields">
				<!-- v3 displaylabel -->
				<xsl:for-each select="@displaylabel">
					<subfield code="3">
						<xsl:value-of select="."/>
					</subfield>
				</xsl:for-each>
				<!-- v3 part/text -->
				<xsl:for-each select="mods:part/mods:text">
					<subfield code="g">
						<xsl:value-of select="."/>
					</subfield>
				</xsl:for-each>
				<!-- v3 sici part/detail 773$q 1:2:3<4 -->
				<xsl:if test="mods:part/mods:detail">
					<subfield code="q">
						<xsl:value-of select="concat(
							mods:part/mods:detail[@type='volume']/mods:number, '(',
							$dateIssued, '), ',
							mods:part/mods:detail[@type='issue']/mods:number, ', ',
							'Seite ', mods:part/mods:extent/mods:start, '-',
							mods:part/mods:extent/mods:end
							)"/>
					</subfield>
				</xsl:if>
				<xsl:call-template name="relatedItem76X-78X"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="mods:relatedItem[@type='host']">
		<xsl:variable name="dateIssued" select="../mods:originInfo/mods:dateIssued"/>
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">773</xsl:with-param>
			<xsl:with-param name="ind1">1</xsl:with-param>
			<xsl:with-param name="ind2">8</xsl:with-param>
			<xsl:with-param name="subfields">
				<!-- v3 part/text -->
				<xsl:for-each select="mods:part/mods:text">
					<subfield code="g">
						<xsl:value-of select="."/>
					</subfield>
				</xsl:for-each>
				<!-- v3 sici part/detail 773$q 1:2:3<4 -->
				<xsl:if test="mods:part/mods:detail">
					<subfield code="q">
						<xsl:value-of select="concat(
							mods:part/mods:detail[@type='volume']/mods:number, '(',
							$dateIssued, '), ',
							mods:part/mods:detail[@type='issue']/mods:number, ', ',
							'Seite ', mods:part/mods:extent/mods:start, '-',
							mods:part/mods:extent/mods:end
							)"/>
					</subfield>
				</xsl:if>
				<xsl:call-template name="relatedItem76X-78X"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="mods:relatedItem[@type='host']">
		<xsl:variable name="dateIssued" select="../mods:originInfo/mods:dateIssued" />
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">773</xsl:with-param>
			<xsl:with-param name="ind1">1</xsl:with-param>
			<xsl:with-param name="ind2">8</xsl:with-param>
			<xsl:with-param name="subfields">
				<subfield code="g">
					<xsl:text>volume:</xsl:text>
					<xsl:value-of select="mods:part/mods:detail[@type='volume']/mods:number"/>
				</subfield>
				<subfield code="g">
					<xsl:text>year:</xsl:text>
					<xsl:value-of select="$dateIssued"/>
				</subfield>
				<subfield code="g">
					<xsl:text>number:</xsl:text>
					<xsl:value-of select="mods:part/mods:detail[@type='issue']/mods:number"/>
				</subfield>
				<subfield code="g">
					<xsl:text>pages:</xsl:text>
					<xsl:value-of select="concat(mods:part/mods:extent/mods:start, '-', mods:part/mods:extent/mods:end)"/>
				</subfield>
				<xsl:call-template name="relatedItem76X-78X"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	
	
	
	
	<xsl:template match="mods:relatedItem[@type='constituent']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">774</xsl:with-param>
			<xsl:with-param name="ind1">0</xsl:with-param>
			<xsl:with-param name="subfields">
				<xsl:call-template name="relatedItem76X-78X"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	
	<!-- v3 changed this to not@type -->
	<!--<xsl:template match="mods:relatedItem[@type='related']">
		<xsl:call-template name="datafield">
			<xsl:with-param name="tag">787</xsl:with-param>
			<xsl:with-param name="ind1">0</xsl:with-param>
			<xsl:with-param name="subfields">
				<xsl:call-template name="relatedItem76X-78X"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
-->
	<xsl:template name="relatedItem76X-78X">
		<xsl:for-each select="mods:titleInfo">
			<!-- 3.02 -->
			<xsl:for-each select="mods:title">
				<subfield code="t">
					<xsl:value-of select="."/>
				</subfield>
			</xsl:for-each>
			<xsl:for-each select="mods:partNumber">
				<subfield code="g">
					<xsl:value-of select="."/>
				</subfield>
			</xsl:for-each>
			<xsl:for-each select="mods:partName">
				<subfield code="g">
					<xsl:value-of select="."/>
				</subfield>
			</xsl:for-each>
		</xsl:for-each>
		<!-- 1/04 fix -->
		<xsl:call-template name="relatedItemNames"/>
		<!-- 1/04 fix -->
		<xsl:choose>
			<xsl:when test="@type='original'"><!-- 534 -->
				<xsl:for-each select="mods:physicalDescription/mods:extent">
					<subfield code="e">
						<xsl:value-of select="."/>
					</subfield>
				</xsl:for-each>
			</xsl:when>
			<xsl:when test="@type!='original'">
				<xsl:for-each select="mods:physicalDescription/mods:extent">
					<subfield code="h">
						<xsl:value-of select="."/>
					</subfield>
				</xsl:for-each>
			</xsl:when>
		</xsl:choose>
		<!-- v3 displaylabel -->
		<xsl:for-each select="@displayLabel">
			<subfield code="i">
				<xsl:value-of select="."/>
			</subfield>
		</xsl:for-each>
		<xsl:for-each select="mods:note">
			<subfield code="n">
				<xsl:value-of select="."/>
			</subfield>
		</xsl:for-each>
		<xsl:for-each select="mods:identifier[not(@type)]">
			<subfield code="o">
				<xsl:value-of select="."/>
			</subfield>
		</xsl:for-each>
		<xsl:for-each select="mods:identifier[@type='issn']">
			<subfield code="x">
				<xsl:value-of select="."/>
			</subfield>
		</xsl:for-each>
		<xsl:for-each select="mods:identifier[@type='isbn']">
			<subfield code="z">
				<xsl:value-of select="."/>
			</subfield>
		</xsl:for-each>
		<xsl:for-each select="mods:identifier[@type='local']">
			<subfield code="w">
				<xsl:value-of select="."/>
			</subfield>
		</xsl:for-each>
		<xsl:for-each select="mods:note">
			<subfield code="n">
				<xsl:value-of select="."/>
			</subfield>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="relatedItemNames">
		<xsl:if test="mods:name">
			<subfield code="a">
				<xsl:variable name="nameString">
					<xsl:for-each select="mods:name">
						<xsl:value-of select="mods:namePart[1][not(@type='date')]"/>
						<xsl:if test="mods:namePart[position()&gt;1][@type='date']">
							<xsl:value-of select="concat(' ',mods:namePart[position()&gt;1][@type='date'])"/>
						</xsl:if>
						<xsl:choose>
							<xsl:when test="mods:role/mods:roleTerm[@type='text']">
								<xsl:value-of select="concat(', ',mods:role/mods:roleTerm)"/>
							</xsl:when>
							<xsl:when test="mods:role/mods:roleTerm[@type='code']">
								<xsl:value-of select="concat(', ',mods:role/mods:roleTerm)"/>
							</xsl:when>
						</xsl:choose>
					</xsl:for-each>
					<xsl:text>, </xsl:text>
				</xsl:variable>
				<xsl:value-of select="substring($nameString, 1,string-length($nameString)-2)"/>
			</subfield>
		</xsl:if>
	</xsl:template>


	<!-- v3 not used?
		<xsl:variable name="leader06">
			<xsl:choose>
				<xsl:when test="mods:typeOfResource='text'">
					<xsl:choose>
						<xsl:when test="@manuscript='yes'">t</xsl:when>
						<xsl:otherwise>a</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="mods:typeOfResource='cartographic'">
					<xsl:choose>
						<xsl:when test="@manuscript='yes'">f</xsl:when>
						<xsl:otherwise>e</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="mods:typeOfResource='notated music'">
					<xsl:choose>
						<xsl:when test="@manuscript='yes'">d</xsl:when>
						<xsl:otherwise>c</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="mods:typeOfResource='sound recording'">j</xsl:when>
				<xsl:when test="mods:typeOfResource='still image'">k</xsl:when>
				<xsl:when test="mods:typeOfResource='moving image'">g</xsl:when>
				<xsl:when test="mods:typeOfResource='three dimensional object'">r</xsl:when>
				<xsl:when test="mods:typeOfResource='software, multimedia'">m</xsl:when>
				<xsl:when test="mods:typeOfResource='mixed material'">p</xsl:when>
			</xsl:choose>
		</xsl:variable>
-->

</xsl:stylesheet>
