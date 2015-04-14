/*******************************************************************************
 * Copyright (c) 2015 itemis AG (http://www.itemis.eu) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package org.eclipse.xtend.core.idea.validation

import com.google.inject.Inject
import com.intellij.psi.JavaDirectoryService
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtend.core.macro.XAnnotationExtensions
import org.eclipse.xtend.core.validation.IssueCodes
import org.eclipse.xtend.core.xtend.XtendFile
import org.eclipse.xtend.core.xtend.XtendPackage
import org.eclipse.xtext.common.types.JvmType
import org.eclipse.xtext.common.types.TypesPackage
import org.eclipse.xtext.psi.IPsiModelAssociations
import org.eclipse.xtext.validation.AbstractDeclarativeValidator
import org.eclipse.xtext.validation.Check
import org.eclipse.xtext.validation.ValidationMessageAcceptor
import org.eclipse.xtext.xbase.XbasePackage
import org.eclipse.xtext.xbase.annotations.xAnnotations.XAnnotation
import org.eclipse.xtext.xbase.annotations.xAnnotations.XAnnotationsPackage
import org.eclipse.xtext.xtype.XtypePackage

import static org.eclipse.xtend.core.validation.IssueCodes.ACTIVE_ANNOTAION_IN_SAME_CONTAINER

import static extension org.eclipse.xtext.idea.extensions.IdeaProjectExtensions.*
import static extension org.eclipse.xtext.util.Strings.*

/**
 * @author kosyakov - Initial contribution and API
 */
class XtendIdeaValidator extends AbstractDeclarativeValidator {

	@Inject
	extension IPsiModelAssociations

	@Inject
	extension XAnnotationExtensions

	override protected getEPackages() {
		#[
			TypesPackage.eINSTANCE,
			XtypePackage.eINSTANCE,
			XbasePackage.eINSTANCE,
			XAnnotationsPackage.eINSTANCE,
			XtendPackage.eINSTANCE
		]
	}

	@Check
	def void checkAnnotationInSameModule(XAnnotation annotation) {
		if (annotation.processed) {
			val annotationType = annotation.annotationType
			if (isSameModule(annotation, annotationType)) {
				error(
					"The referenced active annotation cannot be used from within the same module.",
					XAnnotationsPackage.Literals.XANNOTATION__ANNOTATION_TYPE,
					-1,
					ACTIVE_ANNOTAION_IN_SAME_CONTAINER
				)
			}
		}
	}
	
	protected def isSameModule(XAnnotation annotation, JvmType annotationType) {
		val annotationModule = annotation.module
		annotationModule != null && annotationModule == annotationType.module
	}
	
	protected def getModule(EObject object) {
		val psiElement = object.psiElement
		if (psiElement == null) {
			return null
		}
		val extension projectFileIndex = psiElement.project.projectFileIndex
		psiElement.containingFile.virtualFile.getModuleForFile(false)
	}

	@Check
	def void checkFileNameConventions(XtendFile xtendFile) {
		var expectedPackage = xtendFile.expectedPackageName
		if (expectedPackage == null) {
			return
		}
		var declaredPackage = xtendFile.package
		if (expectedPackage.empty && declaredPackage == null) {
			return
		}
		if (expectedPackage == declaredPackage) {
			return
		}
		error(
			'''The declared package '«declaredPackage.notNull»' does not match the expected package '«expectedPackage.notNull»'«»''',
			XtendPackage.Literals.XTEND_FILE__PACKAGE,
			ValidationMessageAcceptor.INSIGNIFICANT_INDEX,
			IssueCodes.WRONG_PACKAGE,
			expectedPackage
		)
	}

	protected def getExpectedPackageName(XtendFile xtendFile) {
		val psiElement = xtendFile.psiElement
		if (psiElement == null) {
			return null
		}
		val extension javaDirectoryService = JavaDirectoryService.instance
		psiElement.containingFile.originalFile.containingDirectory.package.qualifiedName
	}

}